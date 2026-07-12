import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_outbound_sender.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/mappers/message_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/message_cache_queue_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/read_receipt_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/infrastructure/utils/message_deduplicator.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';

// 全局消息去重器，防止 WebSocket 重复推送导致界面重复渲染
final _messageDeduplicator = MessageDeduplicator(maxSize: 1000);

final Map<String, Timer> _singleChatPresenceRefreshTimers = <String, Timer>{};

// 批量消息缓冲：key 为 chatId，用于节流高频 WebSocket 消息
final Map<String, List<Map<String, dynamic>>> _messageBatchBuffers = <String, List<Map<String, dynamic>>>{};
final Map<String, Timer> _messageBatchTimers = <String, Timer>{};

final chatRealtimeBindingProvider = Provider.autoDispose.family<void, String>((
  ref,
  chatId,
) {
  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleChatSocketEvent(ref, chatId, event));
  ref.onDispose(() {
    subscription.cancel();
    _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
    // 清理批量缓冲
    _messageBatchBuffers.remove(chatId);
    _messageBatchTimers.remove(chatId)?.cancel();
    // 清理该聊天窗口的去重缓存，释放内存
    _messageDeduplicator.clearByChatId(chatId);
  });
});

void _handleChatSocketEvent(Ref ref, String chatId, ImSocketEvent event) {
  if (event.chatId != null && event.chatId != chatId) {
    return;
  }

  switch (event.type) {
    case SocketEventTypes.messageReceived:
      final raw = Map<String, dynamic>.from(event.payload);
      if (!_belongsToCurrentConversation(ref, chatId, raw)) {
        return;
      }
      // 被踢/退群/群解散后忽略新消息
      if (_isGroupLeftStatus(ref, chatId)) {
        return;
      }
      final currentUserId = ref.read(authSessionProvider).userId;
      final senderId = raw['senderId']?.toString() ?? '';
      final isSelf = currentUserId.isNotEmpty && senderId == currentUserId;
      if (isSelf) {
        raw['isOutgoing'] = true;
        raw['isSelf'] = true;
        final rawStatus = raw['status']?.toString().trim().toLowerCase() ?? '';
        raw['status'] = rawStatus.isEmpty || rawStatus == 'delivered'
            ? 'sent'
            : rawStatus;
      }

      // 使用批量节流机制：将消息加入缓冲队列
      _enqueueMessageForBatch(ref, chatId, raw, isSelf, senderId, currentUserId);
      break;
    case SocketEventTypes.readReceiptChanged:
      final messageId =
          event.messageId ?? event.payload['messageId']?.toString();
      if (messageId == null || messageId.isEmpty) {
        return;
      }
      ref
          .read(chatTimelineControllerProvider(chatId).notifier)
          .applyReadReceipt(messageId: messageId);
      ref
          .read(conversationListControllerProvider.notifier)
          .patchLastMessageStatus(
            chatId: chatId,
            messageId: messageId,
            status: MessageStatus.read,
          );
      final summaryStore = ref.read(readReceiptSummaryStoreProvider.notifier);
      final hydrated = _hydrateReadReceiptSummaryFromPayload(event.payload);
      if (hydrated != null) {
        summaryStore.hydrate(hydrated);
      } else {
        final messageIds = _resolveReadReceiptMessageIds(
          event.payload,
          messageId,
        );
        for (final item in messageIds) {
          summaryStore.invalidate(item);
          unawaited(summaryStore.ensureSummary(item));
        }
      }
      break;
    case SocketEventTypes.typingReceived:
      final raw = Map<String, dynamic>.from(event.payload);
      if (!_belongsToCurrentConversation(ref, chatId, raw)) {
        return;
      }
      ref.read(chatRealtimeSignalProvider(chatId).notifier).state = ChatRealtimeSignal(
        chatId: chatId,
        action: 'typing',
        payload: event.payload,
        token: DateTime.now().microsecondsSinceEpoch,
      );
      break;
    case SocketEventTypes.messageRecalled:
      if (!_belongsToCurrentConversation(
        ref,
        chatId,
        Map<String, dynamic>.from(event.payload),
      )) {
        return;
      }
      final session = ref.read(authSessionProvider);
      final recalled = MessageDtoMapper.toEntity(
        MessageDto.fromJson(Map<String, dynamic>.from(event.payload)),
      );
      final existing = ref
          .read(chatTimelineControllerProvider(chatId).notifier)
          .findByAnyMessageId(recalled.messageId);
      final reeditContent = _extractReeditContent(existing);
      if (recalled.isOutgoing &&
          reeditContent != null &&
          reeditContent.isNotEmpty &&
          session.userId.isNotEmpty) {
        final deadlineTs =
            recalled.extra.reeditDeadlineTs ??
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch;
        unawaited(
          ref
              .read(reeditHintLocalStoreProvider)
              .persist(
                tenantId: session.tenantId,
                userId: session.userId,
                chatId: chatId,
                messageId: recalled.messageId,
                content: reeditContent,
                deadlineTs: deadlineTs,
              ),
        );
      }
      final timelineController = ref.read(
        chatTimelineControllerProvider(chatId).notifier,
      );
      timelineController.applyRecalledMessage(recalled);
      final effectiveRecalled =
          timelineController.findByAnyMessageId(recalled.messageId) ?? recalled;
      final pageState = ref.read(chatControllerProvider(chatId));
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: chatId,
            title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
            conversationType: pageState.entryArgs.conversationType,
            targetId: pageState.entryArgs.targetId,
            messageId: effectiveRecalled.messageId,
            messageSequence: effectiveRecalled.sequence,
            preview: createConversationPreviewFormatter(
              ref.read(appLocaleProvider),
            ).call(
              type: effectiveRecalled.type,
              content: effectiveRecalled.content,
              customType: effectiveRecalled.extra.customType,
              fileName: effectiveRecalled.extra.fileName,
              systemEventKey: effectiveRecalled.extra.systemEventKey,
              systemEventParams: effectiveRecalled.extra.systemEventParams,
              conversationType: pageState.entryArgs.conversationType,
              isSelf: effectiveRecalled.isOutgoing,
              senderName: effectiveRecalled.senderName,
            ),
            messageType: effectiveRecalled.type,
            senderName: effectiveRecalled.senderName,
            isSelf: effectiveRecalled.isOutgoing,
            customType: effectiveRecalled.extra.customType,
            fileName: effectiveRecalled.extra.fileName,
            systemEventKey: effectiveRecalled.extra.systemEventKey,
            messageStatus: effectiveRecalled.status,
            updatedAt: effectiveRecalled.sentAt,
            resetUnread: true,
          );
      break;
    case SocketEventTypes.systemNotify:
      _handleSystemNotify(ref, chatId, event.payload);
      break;
    case SocketEventTypes.authSucceeded:
      // WebSocket 重连成功后，触发消息缓存队列重发
      final cacheQueue = ref.read(messageCacheQueueProvider);
      if (cacheQueue.hasPendingMessages) {
        debugPrint(
          '[chatRealtimeBinding] authSucceeded, triggering cache queue retry (${cacheQueue.queueLength} pending)',
        );
        cacheQueue.onSocketReconnected();
      }

      final entryArgs = ref.read(chatControllerProvider(chatId)).entryArgs;
      if (entryArgs.conversationType == ConversationType.direct) {
        _scheduleDirectPresenceRefresh(
          ref,
          chatId,
          delay: const Duration(milliseconds: 120),
        );
      } else if (entryArgs.conversationType == ConversationType.group) {
        final groupId = entryArgs.targetId?.trim() ?? '';
        if (groupId.isNotEmpty) {
        }
      }
      // 根治方案：WebSocket 重连成功后，拉取离线消息（包含对方发来的消息+自己消息状态确认）
      // 原因：后台期间 WebSocket 断开，messageReceived 事件全部丢失
      // 必须通过 HTTP 拉取最新消息补偿，确保消息不丢失
      final command = entryArgs.chatId == chatId
          ? OpenChatCommand.fromArgs(entryArgs)
          : OpenChatCommand(
              chatId: chatId,
              conversationType: entryArgs.conversationType,
              entryMode: ChatEntryMode.latest,
            );
      unawaited(
        ref
            .read(chatTimelineControllerProvider(chatId).notifier)
            .pullMessagesAfterReconnect(command: command),
      );
      unawaited(_rehydrateReeditHints(ref, chatId));
      break;
    default:
      break;
  }
}

List<String> _resolveReadReceiptMessageIds(
  Map<String, Object?> payload,
  String fallbackMessageId,
) {
  final resolved = <String>[];
  final rawIds = payload['messageIds'];
  if (rawIds is List) {
    for (final item in rawIds) {
      final value = item?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '0' && !resolved.contains(value)) {
        resolved.add(value);
      }
    }
  }
  final normalizedFallback = fallbackMessageId.trim();
  if (resolved.isEmpty &&
      normalizedFallback.isNotEmpty &&
      normalizedFallback != '0') {
    resolved.add(normalizedFallback);
  }
  return resolved;
}

ReadReceiptSummary? _hydrateReadReceiptSummaryFromPayload(
  Map<String, Object?> payload,
) {
  final messageId = payload['messageId']?.toString().trim() ?? '';
  final chatId = payload['chatId']?.toString().trim() ?? '';
  final sequence = payload['sequence']?.toString().trim() ?? '';
  final readCount = _tryParseInt(payload['readCount']);
  final unreadCount = _tryParseInt(payload['unreadCount']);
  final totalCount = _tryParseInt(payload['totalCount']);
  if (messageId.isEmpty ||
      chatId.isEmpty ||
      readCount == null ||
      unreadCount == null ||
      totalCount == null) {
    return null;
  }
  return ReadReceiptSummary(
    messageId: messageId,
    chatId: chatId,
    sequence: sequence,
    readCount: readCount,
    unreadCount: unreadCount,
    totalCount: totalCount,
  );
}

int? _tryParseInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

bool _isGroupLeftStatus(Ref ref, String chatId) {
  final pageState = ref.read(chatControllerProvider(chatId));
  final groupMemberStatus = pageState.groupMemberStatus;
  return groupMemberStatus == 1 || groupMemberStatus == 2 || groupMemberStatus == 3;
}

bool _belongsToCurrentConversation(
  Ref ref,
  String chatId,
  Map<String, dynamic> raw,
) {
  final payloadChatId =
      raw['chatId']?.toString().trim() ??
      raw['conversationId']?.toString().trim() ??
      '';
  if (payloadChatId.isNotEmpty &&
      payloadChatId != '0' &&
      chatId.isNotEmpty &&
      payloadChatId != chatId) {
    return false;
  }
  if (payloadChatId.isNotEmpty &&
      payloadChatId != '0' &&
      payloadChatId == chatId) {
    return true;
  }

  final entryArgs = ref.read(chatControllerProvider(chatId)).entryArgs;
  final currentTargetId = entryArgs.targetId?.trim() ?? '';
  if (entryArgs.conversationType == ConversationType.group) {
    final incomingGroupId = raw['groupId']?.toString().trim() ?? '';
    if (incomingGroupId.isEmpty || currentTargetId.isEmpty) {
      return false;
    }
    return incomingGroupId == currentTargetId;
  }

  final currentUserId = ref.read(authSessionProvider).userId.trim();
  final senderId = raw['senderId']?.toString().trim() ?? '';
  final receiverId = raw['receiverId']?.toString().trim() ?? '';
  if (currentTargetId.isEmpty || currentUserId.isEmpty) {
    return false;
  }
  final incomingTargetId = senderId == currentUserId ? receiverId : senderId;
  if (incomingTargetId.isEmpty || incomingTargetId == '0') {
    return false;
  }
  return incomingTargetId == currentTargetId;
}

void _handleSystemNotify(Ref ref, String chatId, Map<String, Object?> payload) {
  final action = payload['action']?.toString() ?? '';
  if (action == 'reedit_after_recall') {
    _handleReeditAfterRecallNotify(ref, chatId, payload);
    return;
  }
  if (action == 'presence_update') {
    _handlePresenceUpdateNotify(ref, chatId, payload);
    return;
  }
  if (action == 'group_info_updated') {
    _handleGroupInfoUpdatedNotify(ref, chatId, payload);
    return;
  }
  if (action == 'voice_played' ||
      action == 'group_member_mute_changed' ||
      action == 'group_mute_all_changed' ||
      action == 'group_member_added' ||
      action == 'group_member_removed' ||
      action == 'group_owner_transferred' ||
      action == 'group_disbanded') {
    ref.read(chatRealtimeSignalProvider(chatId).notifier).state = ChatRealtimeSignal(
      chatId: chatId,
      action: action,
      payload: payload,
      token: DateTime.now().microsecondsSinceEpoch,
    );
    return;
  }
  if (action != 'message_send_denied' && action != 'message_send_failed') {
    return;
  }
  final messageId = payload['messageId']?.toString().trim() ?? '';
  final clientMessageId = payload['clientMessageId']?.toString().trim() ?? '';
  final previousMessageId =
      payload['previousMessageId']?.toString().trim() ?? '';
  final candidates = <String>{messageId, clientMessageId, previousMessageId}
    ..removeWhere((item) => item.isEmpty || item == '0');
  if (candidates.isEmpty) {
    return;
  }

  final timelineController = ref.read(chatTimelineControllerProvider(chatId).notifier);
  final matchedMessage = candidates
      .map(timelineController.findByAnyMessageId)
      .whereType<Message>()
      .firstOrNull;
  final denyCode = payload['code']?.toString().trim() ?? '';
  final denyMessage = payload['message']?.toString().trim() ?? '消息发送失败';
  final resolvedMessageId =
      matchedMessage?.clientMessageId ??
      matchedMessage?.messageId ??
      candidates.first;
  timelineController.markFailedByClientMessageId(
    clientMessageId: resolvedMessageId,
  );
  ref
      .read(conversationListControllerProvider.notifier)
      .patchLastMessageStatus(
        chatId: chatId,
        messageId: resolvedMessageId,
        status: MessageStatus.failed,
      );

  final redirectCodes = <String>[
    'NOT_GROUP_MEMBER',
    'GROUP_MEMBER_NOT_EXISTS',
    'GROUP_NOT_EXISTS',
    'GROUP_DISBANDED',
  ];
  ref.read(chatRuntimeNoticeProvider(chatId).notifier).state = ChatRuntimeNotice(
    chatId: chatId,
    message: denyMessage,
    code: denyCode.isEmpty ? null : denyCode,
    redirectToConversations: redirectCodes.contains(denyCode),
    token: DateTime.now().microsecondsSinceEpoch,
  );
}

void _handlePresenceUpdateNotify(
  Ref ref,
  String chatId,
  Map<String, Object?> payload,
) {
  final pageState = ref.read(chatControllerProvider(chatId));
  if (pageState.entryArgs.conversationType != ConversationType.direct) {
    return;
  }
  final notifyTargetUserId = payload['targetUserId']?.toString().trim() ?? '';
  final currentTargetUserId = pageState.entryArgs.targetId?.trim() ?? '';
  if (notifyTargetUserId.isEmpty ||
      currentTargetUserId.isEmpty ||
      notifyTargetUserId != currentTargetUserId) {
    return;
  }
  final online =
      payload['online'] == true ||
      payload['online']?.toString() == '1' ||
      payload['online']?.toString().toLowerCase() == 'true';
  final lastActiveTime = _parseNotifyTime(payload['lastActiveTime']);
  ref
      .read(conversationListControllerProvider.notifier)
      .patchPresence(
        chatId: chatId,
        online: online,
        onlineDeviceTypes: _parseOnlineDeviceTypes(
          payload['onlineDeviceTypes'],
        ),
        lastActiveTime: lastActiveTime,
      );
}

void _handleGroupInfoUpdatedNotify(
  Ref ref,
  String chatId,
  Map<String, Object?> payload,
) {
  final pageState = ref.read(chatControllerProvider(chatId));
  if (pageState.entryArgs.conversationType != ConversationType.group) {
    return;
  }
  final notifyGroupId = payload['groupId']?.toString().trim() ?? '';
  final currentGroupId = pageState.entryArgs.targetId?.trim() ?? '';
  if (notifyGroupId.isEmpty ||
      currentGroupId.isEmpty ||
      notifyGroupId != currentGroupId) {
    return;
  }
  final newName = payload['newName']?.toString().trim() ?? '';
  if (newName.isEmpty || pageState.chatTitle == newName) {
    return;
  }
  ref
      .read(chatControllerProvider(chatId).notifier)
      .updateChatTitle(newName);
}

int? _parseNotifyTime(Object? raw) {
  final value = int.tryParse(raw?.toString().trim() ?? '');
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

List<int> _parseOnlineDeviceTypes(Object? raw) {
  if (raw is List) {
    return raw
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) {
    return const <int>[];
  }
  return text
      .split(',')
      .map((item) => int.tryParse(item.trim()))
      .whereType<int>()
      .toList(growable: false);
}

void _handleReeditAfterRecallNotify(
  Ref ref,
  String chatId,
  Map<String, Object?> payload,
) {
  final session = ref.read(authSessionProvider);
  if (session.userId.isEmpty || session.tenantId.isEmpty) {
    return;
  }
  final isSelfRecall =
      payload['isSelfRecall'] == true ||
      payload['isSelfRecall']?.toString() == 'true' ||
      payload['isSelfRecall']?.toString() == '1';
  if (!isSelfRecall) {
    return;
  }
  final recallBy = payload['recallBy']?.toString().trim() ?? '';
  final senderId = payload['senderId']?.toString().trim() ?? '';
  if (recallBy != session.userId || senderId != session.userId) {
    return;
  }
  final messageId = payload['messageId']?.toString().trim() ?? '';
  final originalContent = payload['originalContent']?.toString().trim() ?? '';
  final deadlineTs = int.tryParse(
    payload['deadlineTs']?.toString().trim() ?? '',
  );
  if (messageId.isEmpty ||
      originalContent.isEmpty ||
      deadlineTs == null ||
      deadlineTs <= 0) {
    return;
  }
  unawaited(
    ref
        .read(reeditHintLocalStoreProvider)
        .persist(
          tenantId: session.tenantId,
          userId: session.userId,
          chatId: chatId,
          messageId: messageId,
          content: originalContent,
          deadlineTs: deadlineTs,
        ),
  );
  ref
      .read(chatTimelineControllerProvider(chatId).notifier)
      .applyReeditHint(
        messageId: messageId,
        content: originalContent,
        deadlineTs: deadlineTs,
      );
}

String? _extractReeditContent(Message? message) {
  if (message == null ||
      !message.isOutgoing ||
      message.type != MessageType.text) {
    return null;
  }
  if (message.extra.quoteMessageId?.trim().isNotEmpty == true) {
    return null;
  }
  if (message.extra.forwardedFrom?.trim().isNotEmpty == true) {
    return null;
  }
  if (message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE') {
    return null;
  }
  final content = message.content.trim();
  if (content.isEmpty || content.contains('撤回')) {
    return null;
  }
  return content;
}

Future<void> _rehydrateReeditHints(Ref ref, String chatId) async {
  final session = ref.read(authSessionProvider);
  if (session.userId.isEmpty || session.tenantId.isEmpty) {
    return;
  }
  final timeline = ref.read(chatTimelineControllerProvider(chatId));
  if (timeline.messages.isEmpty) {
    return;
  }
  final hydrated = await ref
      .read(reeditHintLocalStoreProvider)
      .rehydrateMessages(
        tenantId: session.tenantId,
        userId: session.userId,
        chatId: chatId,
        messages: timeline.messages,
      );
  var changed = false;
  for (var i = 0; i < hydrated.length; i++) {
    if (hydrated[i].extra.reeditContent !=
            timeline.messages[i].extra.reeditContent ||
        hydrated[i].extra.reeditDeadlineTs !=
            timeline.messages[i].extra.reeditDeadlineTs) {
      changed = true;
      break;
    }
  }
  if (!changed) {
    return;
  }
  await ref
      .read(chatTimelineControllerProvider(chatId).notifier)
      .replaceAllMessages(hydrated);
}

void _markDirectPresenceOnlineNow(Ref ref, String chatId) {
  final conversation = ref
      .read(conversationListControllerProvider)
      .conversations
      .where((item) => item.chatId == chatId)
      .firstOrNull;
  ref
      .read(conversationListControllerProvider.notifier)
      .patchPresence(
        chatId: chatId,
        online: true,
        onlineDeviceTypes: conversation?.onlineDeviceTypes ?? const <int>[],
        lastActiveTime: DateTime.now().millisecondsSinceEpoch,
      );
}

/// 将消息加入批量缓冲队列，并启动 50ms 节流定时器
void _enqueueMessageForBatch(
  Ref ref,
  String chatId,
  Map<String, dynamic> raw,
  bool isSelf,
  String senderId,
  String currentUserId,
) {
  // 消息去重：自己发送的消息（isSelf=true）不做去重，因为需要更新状态
  // 只有对方发送的消息才进行去重，避免重复渲染
  if (!isSelf && _messageDeduplicator.isDuplicate(raw)) {
    return;
  }
  
  // 对于自己发送的消息，也需要加入去重器（避免后续重复推送）
  if (isSelf) {
    _messageDeduplicator.isDuplicate(raw);
  }

  // 初始化缓冲队列
  _messageBatchBuffers.putIfAbsent(chatId, () => <Map<String, dynamic>>[]);
  final buffer = _messageBatchBuffers[chatId]!;

  // 附加上下文信息供后续处理使用
  raw['_isSelf'] = isSelf;
  raw['_senderId'] = senderId;
  raw['_currentUserId'] = currentUserId;
  buffer.add(raw);

  // 如果已有定时器，等待触发（节流）
  if (_messageBatchTimers[chatId] != null) {
    return;
  }

  // 启动 50ms 批量窗口
  _messageBatchTimers[chatId] = Timer(
    const Duration(milliseconds: 50),
    () => _flushMessageBatch(ref, chatId),
  );
}

/// 刷新消息缓冲队列：批量处理消息并更新会话列表
void _flushMessageBatch(Ref ref, String chatId) {
  _messageBatchTimers.remove(chatId);
  final buffer = _messageBatchBuffers.remove(chatId);

  if (buffer == null || buffer.isEmpty) {
    return;
  }

  // 批量转换消息实体
  final messages = <Message>[];
  for (final raw in buffer) {
    final message = MessageDtoMapper.toEntity(MessageDto.fromJson(raw));
    messages.add(message);
  }

  // 调用批量添加方法（Controller 内部会去重合并）
  final timelineController = ref.read(chatTimelineControllerProvider(chatId).notifier);
  timelineController.appendMessagesBatch(messages);

  // 使用最后一条消息更新会话列表
  final lastRaw = buffer.last;
  final lastMessage = messages.last;
  final effectiveMessage =
      timelineController.findByAnyMessageId(lastMessage.messageId) ??
      (lastMessage.clientMessageId?.trim().isNotEmpty == true
          ? timelineController.findByAnyMessageId(lastMessage.clientMessageId!.trim())
          : null) ??
      lastMessage;

  final pageState = ref.read(chatControllerProvider(chatId));
  ref
      .read(conversationListControllerProvider.notifier)
      .upsertLocalMessage(
        chatId: chatId,
        title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
        conversationType: pageState.entryArgs.conversationType,
        targetId: pageState.entryArgs.targetId,
        messageId: effectiveMessage.messageId,
        messageSequence: effectiveMessage.sequence,
        preview: createConversationPreviewFormatter(
          ref.read(appLocaleProvider),
        ).call(
          type: effectiveMessage.type,
          content: effectiveMessage.content,
          customType: effectiveMessage.extra.customType,
          fileName: effectiveMessage.extra.fileName,
          systemEventKey: effectiveMessage.extra.systemEventKey,
          systemEventParams: effectiveMessage.extra.systemEventParams,
          conversationType: pageState.entryArgs.conversationType,
          isSelf: effectiveMessage.isOutgoing,
          senderName: effectiveMessage.senderName,
        ),
        messageType: effectiveMessage.type,
        senderName: effectiveMessage.senderName,
        isSelf: effectiveMessage.isOutgoing,
        customType: effectiveMessage.extra.customType,
        fileName: effectiveMessage.extra.fileName,
        systemEventKey: effectiveMessage.extra.systemEventKey,
        messageStatus: effectiveMessage.status,
        updatedAt: effectiveMessage.sentAt,
        resetUnread: true,
      );

  // 处理单聊在线状态刷新
  if (pageState.entryArgs.conversationType == ConversationType.direct) {
    final lastIsSelf = lastRaw['_isSelf'] == true;
    if (!lastIsSelf) {
      _markDirectPresenceOnlineNow(ref, chatId);
    }
    _scheduleDirectPresenceRefresh(
      ref,
      chatId,
      delay: Duration(milliseconds: lastIsSelf ? 800 : 200),
    );
  }

  // 处理单聊已读回执（为所有非自己发送的消息发送已读）
  final currentUserId = lastRaw['_currentUserId']?.toString() ?? '';
  for (final raw in buffer) {
    final isSelf = raw['_isSelf'] == true;
    if (!isSelf &&
        pageState.entryArgs.conversationType == ConversationType.direct) {
      final messageId = (raw['messageId']?.toString() ?? '').trim();
      final senderId = (raw['_senderId']?.toString() ?? '').trim();
      if (messageId.isNotEmpty && messageId != '0') {
        unawaited(
          ref
              .read(socketOutboundSenderProvider)
              .sendReadReceiptIfConnected(
                senderId: currentUserId,
                receiverId: senderId,
                tenantId: ref.read(authSessionProvider).tenantId,
                messageIds: <String>[messageId],
              ),
        );
      }
    }
  }
}

void _scheduleDirectPresenceRefresh(
  Ref ref,
  String chatId, {
  required Duration delay,
}) {
  final entryArgs = ref.read(chatControllerProvider(chatId)).entryArgs;
  if (entryArgs.conversationType != ConversationType.direct) {
    _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
    return;
  }
  _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
  // 优化：移除 syncIncrementally 调用
  // 原因：用户当前已在聊天页面，在线状态变化已通过 patchPresence 更新到本地会话列表
  // 不需要触发完整的会话列表同步
  _singleChatPresenceRefreshTimers[chatId] = Timer(delay, () {
    _singleChatPresenceRefreshTimers.remove(chatId);
    // 仅清理定时器，不再触发 sync
  });
}
