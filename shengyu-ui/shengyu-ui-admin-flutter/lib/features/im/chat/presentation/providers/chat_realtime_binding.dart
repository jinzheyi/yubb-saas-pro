import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_outbound_sender.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/mappers/message_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';

final Map<String, Timer> _singleChatPresenceRefreshTimers = <String, Timer>{};

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
      final message = MessageDtoMapper.toEntity(MessageDto.fromJson(raw));
      final timelineController = ref.read(
        chatTimelineControllerProvider.notifier,
      );
      timelineController.appendSingleMessage(message);
      final effectiveMessage =
          timelineController.findByAnyMessageId(message.messageId) ??
          (message.clientMessageId?.trim().isNotEmpty == true
              ? timelineController.findByAnyMessageId(
                  message.clientMessageId!.trim(),
                )
              : null) ??
          message;
      final pageState = ref.read(chatControllerProvider);
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: chatId,
            title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
            conversationType: pageState.entryArgs.conversationType,
            messageId: effectiveMessage.messageId,
            messageSequence: effectiveMessage.sequence,
            preview: ref
                .read(messagePreviewFormatterProvider)
                .formatConversationPreview(
                  type: effectiveMessage.type,
                  content: effectiveMessage.content,
                  customType: effectiveMessage.extra.customType,
                  fileName: effectiveMessage.extra.fileName,
                  systemEventKey: effectiveMessage.extra.systemEventKey,
                  conversationType: pageState.entryArgs.conversationType,
                  isSelf: effectiveMessage.isOutgoing,
                  senderName: effectiveMessage.senderName,
                ),
            messageType: effectiveMessage.type,
            messageStatus: effectiveMessage.status,
            updatedAt: effectiveMessage.sentAt,
            resetUnread: true,
          );
      if (pageState.entryArgs.conversationType == ConversationType.direct) {
        if (!isSelf) {
          _markDirectPresenceOnlineNow(ref, chatId);
        }
        _scheduleDirectPresenceRefresh(
          ref,
          chatId,
          delay: Duration(milliseconds: isSelf ? 800 : 200),
        );
      }
      if (!isSelf &&
          pageState.entryArgs.conversationType == ConversationType.direct) {
        final messageId = effectiveMessage.messageId.trim();
        if (messageId.isNotEmpty && messageId != '0') {
          unawaited(
            ref.read(socketOutboundSenderProvider).sendReadReceiptIfConnected(
              senderId: currentUserId,
              receiverId: senderId,
              tenantId: ref.read(authSessionProvider).tenantId,
              messageIds: <String>[messageId],
            ),
          );
        }
      }
      break;
    case SocketEventTypes.readReceiptChanged:
      final messageId =
          event.messageId ?? event.payload['messageId']?.toString();
      if (messageId == null || messageId.isEmpty) {
        return;
      }
      ref
          .read(chatTimelineControllerProvider.notifier)
          .applyReadReceipt(messageId: messageId);
      ref
          .read(conversationListControllerProvider.notifier)
          .patchLastMessageStatus(
            chatId: chatId,
            messageId: messageId,
            status: MessageStatus.read,
          );
      break;
    case SocketEventTypes.typingReceived:
      final raw = Map<String, dynamic>.from(event.payload);
      if (!_belongsToCurrentConversation(ref, chatId, raw)) {
        return;
      }
      ref.read(chatRealtimeSignalProvider.notifier).state = ChatRealtimeSignal(
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
          .read(chatTimelineControllerProvider.notifier)
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
        chatTimelineControllerProvider.notifier,
      );
      timelineController.applyRecalledMessage(recalled);
      final effectiveRecalled =
          timelineController.findByAnyMessageId(recalled.messageId) ?? recalled;
      final pageState = ref.read(chatControllerProvider);
      ref
          .read(conversationListControllerProvider.notifier)
          .upsertLocalMessage(
            chatId: chatId,
            title: pageState.chatTitle ?? pageState.entryArgs.title ?? '',
            conversationType: pageState.entryArgs.conversationType,
            messageId: effectiveRecalled.messageId,
            messageSequence: effectiveRecalled.sequence,
            preview: ref
                .read(messagePreviewFormatterProvider)
                .formatConversationPreview(
                  type: effectiveRecalled.type,
                  content: effectiveRecalled.content,
                  customType: effectiveRecalled.extra.customType,
                  fileName: effectiveRecalled.extra.fileName,
                  systemEventKey: effectiveRecalled.extra.systemEventKey,
                  conversationType: pageState.entryArgs.conversationType,
                  isSelf: effectiveRecalled.isOutgoing,
                  senderName: effectiveRecalled.senderName,
                ),
            messageType: effectiveRecalled.type,
            messageStatus: effectiveRecalled.status,
            updatedAt: effectiveRecalled.sentAt,
            resetUnread: true,
          );
      break;
    case SocketEventTypes.systemNotify:
      _handleSystemNotify(ref, chatId, event.payload);
      break;
    case SocketEventTypes.authSucceeded:
      final entryArgs = ref.read(chatControllerProvider).entryArgs;
      if (entryArgs.conversationType == ConversationType.direct) {
        _scheduleDirectPresenceRefresh(
          ref,
          chatId,
          delay: const Duration(milliseconds: 120),
        );
      } else if (entryArgs.conversationType == ConversationType.group) {
        final groupId = entryArgs.targetId?.trim() ?? '';
        if (groupId.isNotEmpty) {
          unawaited(
            ref.read(conversationListControllerProvider.notifier).syncIncrementally(),
          );
          final args = GroupContextArgs(groupId: groupId, groupName: '');
          unawaited(
            ref.read(groupSettingsControllerProvider(args).notifier).load(),
          );
          unawaited(
            ref.read(groupMembersControllerProvider(args).notifier).load(),
          );
        }
      }
      final command = entryArgs.chatId == chatId
          ? OpenChatCommand.fromArgs(entryArgs)
          : OpenChatCommand(
              chatId: chatId,
              conversationType: entryArgs.conversationType,
              entryMode: ChatEntryMode.latest,
            );
      unawaited(() async {
        await ref
            .read(chatTimelineControllerProvider.notifier)
            .reloadLatest(command: command);
        await _rehydrateReeditHints(ref, chatId);
      }());
      break;
    default:
      break;
  }
}

bool _belongsToCurrentConversation(
  Ref ref,
  String currentChatId,
  Map<String, dynamic> raw,
) {
  final payloadChatId =
      raw['chatId']?.toString().trim() ??
      raw['conversationId']?.toString().trim() ??
      '';
  if (payloadChatId.isNotEmpty &&
      payloadChatId != '0' &&
      currentChatId.isNotEmpty &&
      payloadChatId != currentChatId) {
    return false;
  }
  if (payloadChatId.isNotEmpty &&
      payloadChatId != '0' &&
      payloadChatId == currentChatId) {
    return true;
  }

  final entryArgs = ref.read(chatControllerProvider).entryArgs;
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
  if (action == 'voice_played' ||
      action == 'group_member_mute_changed' ||
      action == 'group_mute_all_changed' ||
      action == 'group_member_added' ||
      action == 'group_member_removed' ||
      action == 'group_owner_transferred') {
    ref.read(chatRealtimeSignalProvider.notifier).state = ChatRealtimeSignal(
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

  final timelineController = ref.read(chatTimelineControllerProvider.notifier);
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
  ref.read(chatRuntimeNoticeProvider.notifier).state = ChatRuntimeNotice(
    chatId: chatId,
    message: denyMessage,
    code: denyCode.isEmpty ? null : denyCode,
    redirectToConversations:
        denyCode == 'NOT_GROUP_MEMBER' || denyCode == 'GROUP_MEMBER_NOT_EXISTS',
    token: DateTime.now().microsecondsSinceEpoch,
  );
}

void _handlePresenceUpdateNotify(
  Ref ref,
  String chatId,
  Map<String, Object?> payload,
) {
  final pageState = ref.read(chatControllerProvider);
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
      .read(chatTimelineControllerProvider.notifier)
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
  final timeline = ref.read(chatTimelineControllerProvider);
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
  ref
      .read(chatTimelineControllerProvider.notifier)
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

void _scheduleDirectPresenceRefresh(
  Ref ref,
  String chatId, {
  required Duration delay,
}) {
  final entryArgs = ref.read(chatControllerProvider).entryArgs;
  if (entryArgs.conversationType != ConversationType.direct) {
    _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
    return;
  }
  _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
  _singleChatPresenceRefreshTimers[chatId] = Timer(delay, () async {
    _singleChatPresenceRefreshTimers.remove(chatId);
    try {
      await ref.read(conversationListControllerProvider.notifier).syncIncrementally();
    } catch (_) {
      // Keep silent to match old page presence refresh compensation.
    }
  });
}
