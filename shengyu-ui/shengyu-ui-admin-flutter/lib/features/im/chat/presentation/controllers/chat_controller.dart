import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/network/network_monitor_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_outbound_sender.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/mark_conversation_read_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/open_chat_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/data/message_cache_queue.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_page_state.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart'
    show ConversationPreviewFormatter;
import 'package:uuid/uuid.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/unified_cache_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';

class ChatController extends StateNotifier<ChatPageState> {
  ChatController(
    this._openChatUseCase,
    this._sendMessageUseCase,
    this._markConversationReadUseCase,
    this._optimisticMessageFactory,
    this._messagePreviewFormatter,
    this._conversationListController,
    this._timelineController, {
    ImSocketClient? socketClient,
    SocketOutboundSender? socketOutboundSender,
    UnifiedCacheManager? unifiedCacheManager,
    String? currentUserId,
  })  : _socketClient = socketClient,
        _socketOutboundSender = socketOutboundSender,
        _unifiedCacheManager = unifiedCacheManager,
        _currentUserId = currentUserId,
        super(const ChatPageState(entryArgs: ChatEntryArgs.empty()));

  final OpenChatUseCase _openChatUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkConversationReadUseCase _markConversationReadUseCase;
  final OptimisticMessageFactory _optimisticMessageFactory;
  final ConversationPreviewFormatter _messagePreviewFormatter;
  final ConversationListController _conversationListController;
  final ChatTimelineController _timelineController;
  final ImSocketClient? _socketClient;
  final SocketOutboundSender? _socketOutboundSender;
  final UnifiedCacheManager? _unifiedCacheManager;
  final String? _currentUserId;

  /// 消息缓存队列（断网时缓存消息，网络恢复后自动重发）
  MessageCacheQueue? _cacheQueue;

  /// 设置消息缓存队列
  void setCacheQueue(MessageCacheQueue queue) {
    _cacheQueue = queue;
    // 注册状态变更回调：队列重发成功/失败时更新 UI
    queue.registerStatusChangeCallback((clientMessageId, success) {
      if (success) {
        _timelineController.markSentByClientMessageId(
          clientMessageId: clientMessageId,
        );
        _conversationListController.patchLastMessageStatus(
          chatId: state.entryArgs.chatId,
          messageId: clientMessageId,
          status: MessageStatus.sent,
        );
      } else {
        _timelineController.markFailedByClientMessageId(
          clientMessageId: clientMessageId,
        );
        _conversationListController.patchLastMessageStatus(
          chatId: state.entryArgs.chatId,
          messageId: clientMessageId,
          status: MessageStatus.failed,
        );
      }
    });
  }

  void updateChatTitle(String title) {
    if (state.chatTitle == title) {
      return;
    }
    state = state.copyWith(chatTitle: title);
  }

  Future<void> initialize(ChatEntryArgs args) async {
    state = state.copyWith(
      entryArgs: args,
      pageStatus: ChatPageStatus.initializing,
      error: null,
    );

    // ========== 【Phase 4】缓存优先策略 ==========
    // 1. 尝试从缓存加载消息
    if (_unifiedCacheManager != null && _currentUserId != null) {
      final cached = await _unifiedCacheManager.getMessages(
        _currentUserId!,
        args.chatId,
      );

      if (cached != null && cached.data.isNotEmpty) {
        // 先显示缓存消息（跳过骨架屏）
        await _timelineController.applyWindow(
          ChatWindowResult(
            messages: cached.data,
            viewportState: cached.viewportState ?? const ChatViewportState(anchorMessageId: null, hasMoreBefore: true, hasMoreAfter: true),
            chatId: args.chatId,
          ),
        );

        // 设置 ready 状态（跳过 initializing 的骨架屏）
        state = state.copyWith(
          pageStatus: ChatPageStatus.ready,
          isReadOnly: args.isReadOnly,
          highlightedMessageId: args.highlightedMessageId,
        );

        debugPrint('[ChatController] Cache hit, showing cached messages (${cached.data.length} messages)');

        // 后台拉取最新消息并合并
        _backgroundRefreshMessages(args);
        return;
      }
    }
    // ========== 【Phase 4 结束】 ==========

    // 原有逻辑：从网络加载
    try {
      final result = await _openChatUseCase(OpenChatCommand.fromArgs(args));
      await _timelineController.applyWindow(result.window);
      final readSequence = _resolveLatestReadableSequence(
        result.window.messages,
      );
      if (readSequence != null) {
        await _markConversationReadUseCase(
          chatId: args.chatId,
          readSequence: readSequence,
        );
      }
      _conversationListController.markConversationRead(args.chatId);
      state = state.copyWith(
        pageStatus: ChatPageStatus.ready,
        chatTitle: result.chatTitle,
        isReadOnly: args.isReadOnly,
        highlightedMessageId: args.highlightedMessageId,
      );

      // ========== 【Phase 4】写入缓存 ==========
      if (_unifiedCacheManager != null && _currentUserId != null) {
        await _unifiedCacheManager.setMessages(
          _currentUserId!,
          args.chatId,
          result.window.messages,
          result.window.viewportState,
        );
      }
      // ========== 【Phase 4 结束】 ==========
    } catch (error, stackTrace) {
      // ========== 【Phase 4】网络失败时降级到过期缓存 ==========
      if (_unifiedCacheManager != null && _currentUserId != null) {
        final staleCached = await _unifiedCacheManager.getMessages(
          _currentUserId!,
          args.chatId,
        );
        if (staleCached != null && staleCached.data.isNotEmpty) {
          debugPrint('[ChatController] Network failed, using stale cache');
          await _timelineController.applyWindow(
            ChatWindowResult(
              messages: staleCached.data,
              viewportState: staleCached.viewportState ?? const ChatViewportState(anchorMessageId: null, hasMoreBefore: true, hasMoreAfter: true),
              chatId: args.chatId,
            ),
          );
          state = state.copyWith(
            pageStatus: ChatPageStatus.ready,
          );
          return;
        }
      }
      // ========== 【Phase 4 结束】 ==========

      state = state.copyWith(
        pageStatus: ChatPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  /// 【Phase 4】后台刷新消息（缓存命中后调用）
  Future<void> _backgroundRefreshMessages(ChatEntryArgs args) async {
    try {
      final result = await _openChatUseCase(OpenChatCommand.fromArgs(args));

      if (!mounted) return;

      // 合并最新消息到时间线
      await _timelineController.applyWindow(result.window);

      // 更新标题
      if (result.chatTitle != null) {
        state = state.copyWith(chatTitle: result.chatTitle);
      }

      // 标记已读
      final readSequence = _resolveLatestReadableSequence(result.window.messages);
      if (readSequence != null) {
        await _markConversationReadUseCase(
          chatId: args.chatId,
          readSequence: readSequence,
        );
      }
      _conversationListController.markConversationRead(args.chatId);

      // 更新缓存
      if (_unifiedCacheManager != null && _currentUserId != null) {
        await _unifiedCacheManager.setMessages(
          _currentUserId!,
          args.chatId,
          result.window.messages,
          result.window.viewportState,
        );
      }
    } catch (e) {
      debugPrint('[ChatController] Background refresh failed: $e');
      // 静默失败，缓存数据仍然可用
    }
  }

  String? _resolveLatestReadableSequence(List<Message> messages) {
    for (final message in messages.reversed) {
      final sequence = message.sequence?.trim() ?? '';
      if (sequence.isNotEmpty && sequence != '0') {
        return sequence;
      }
    }
    return null;
  }

  Future<bool> sendText(
    String text, {
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) async {
    if (text.trim().isEmpty) {
      return false;
    }

    final optimisticMessage = _optimisticMessageFactory.createText(
      chatId: state.entryArgs.chatId,
      content: text,
      quoteInfo: quoteInfo,
      atUserIds: atUserIds,
      mentions: mentions,
    );
    _timelineController.appendSingleMessage(optimisticMessage);
    _patchConversationForMessage(optimisticMessage, resetUnread: true);
    return _submitTextMessage(optimisticMessage);
  }

  Future<bool> retryFailedMessage(String messageId) async {
    final failedMessage = _timelineController.findByAnyMessageId(messageId);
    if (failedMessage == null || failedMessage.status != MessageStatus.failed) {
      return false;
    }

    if (_isContactCardMessage(failedMessage)) {
      final payload = _restoreContactCardPayload(failedMessage);
      if (payload == null) {
        return false;
      }
      final retryKey = failedMessage.clientMessageId ?? failedMessage.messageId;
      _timelineController.markSendingByClientMessageId(
        clientMessageId: retryKey,
      );
      _patchConversationForMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        resetUnread: true,
      );
      return _submitContactCardMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        payload,
      );
    }

    if (failedMessage.type == MessageType.location) {
      final payload = _restoreLocationPayload(failedMessage);
      if (payload == null) {
        return false;
      }
      final retryKey = failedMessage.clientMessageId ?? failedMessage.messageId;
      _timelineController.markSendingByClientMessageId(
        clientMessageId: retryKey,
      );
      _patchConversationForMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        resetUnread: true,
      );
      return _submitLocationMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        payload,
      );
    }

    if (failedMessage.type == MessageType.sticker) {
      final payload = _restoreStickerPayload(failedMessage);
      if (payload == null) {
        return false;
      }
      final retryKey = failedMessage.clientMessageId ?? failedMessage.messageId;
      _timelineController.markSendingByClientMessageId(
        clientMessageId: retryKey,
      );
      _patchConversationForMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        resetUnread: true,
      );
      return _submitStickerMessage(
        failedMessage.copyWith(status: MessageStatus.sending),
        payload,
      );
    }

    if (failedMessage.type != MessageType.text) {
      return false;
    }

    final retryKey = failedMessage.clientMessageId ?? failedMessage.messageId;
    _timelineController.markSendingByClientMessageId(clientMessageId: retryKey);
    _patchConversationForMessage(
      failedMessage.copyWith(status: MessageStatus.sending),
      resetUnread: true,
    );
    return _submitTextMessage(failedMessage);
  }

  Future<bool> sendContactCard(ContactCardSharePayload payload) async {
    final optimisticMessage = _optimisticMessageFactory.createContactCard(
      chatId: state.entryArgs.chatId,
      payload: payload,
    );
    _timelineController.appendSingleMessage(optimisticMessage);
    _patchConversationForMessage(optimisticMessage, resetUnread: true);
    return _submitContactCardMessage(optimisticMessage, payload);
  }

  Future<bool> sendLocation(LocationSharePayload payload) async {
    final optimisticMessage = _optimisticMessageFactory.createLocation(
      chatId: state.entryArgs.chatId,
      payload: payload,
    );
    _timelineController.appendSingleMessage(optimisticMessage);
    _patchConversationForMessage(optimisticMessage, resetUnread: true);
    return _submitLocationMessage(optimisticMessage, payload);
  }

  Future<bool> sendSticker(StickerPayload payload) async {
    final optimisticMessage = _optimisticMessageFactory.createSticker(
      chatId: state.entryArgs.chatId,
      payload: payload,
    );
    _timelineController.appendSingleMessage(optimisticMessage);
    _patchConversationForMessage(optimisticMessage, resetUnread: true);
    return _submitStickerMessage(optimisticMessage, payload);
  }

  Future<bool> _submitTextMessage(Message localMessage) async {
    final clientMessageId =
        localMessage.clientMessageId ?? localMessage.messageId;
    final target = _resolveLegacySendTarget();

    // 断网时：加入缓存队列
    if (!_isNetworkAvailable()) {
      debugPrint(
        '[ChatController] network unavailable, enqueueing: $clientMessageId',
      );
      _cacheQueue?.enqueue(
        PendingMessage(
          id: const Uuid().v4(),
          chatId: localMessage.chatId,
          clientMessageId: clientMessageId,
          content: localMessage.content,
          receiverId: target.receiverId,
          groupId: target.groupId,
        ),
      );
      state = state.copyWith(pendingAction: ChatPendingAction.none);
      return true; // 消息已缓存，不视为失败
    }

    state = state.copyWith(
      pendingAction: ChatPendingAction.sendingMessage,
      error: null,
    );

    try {
      // WebSocket 优先发送
      final wsSent = await _trySendViaWebSocket(
        clientMessageId: clientMessageId,
        localMessage: localMessage,
        target: target,
      );
      if (wsSent) {
        return true;
      }
      // WebSocket 不可用或未确认：降级为 HTTP
      return _submitTextMessageViaHttp(localMessage, clientMessageId, target);
    } catch (error, stackTrace) {
      _timelineController.markFailedByClientMessageId(
        clientMessageId: clientMessageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: clientMessageId,
        status: MessageStatus.failed,
      );
      state = state.copyWith(
        pendingAction: ChatPendingAction.none,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return false;
    }
  }

  /// 尝试通过 WebSocket 发送消息，返回 true 表示发送成功，false 表示 WebSocket 不可用需降级 HTTP。
  /// 若 WebSocket 发送失败（抛出异常），也会返回 false。
  Future<bool> _trySendViaWebSocket({
    required String clientMessageId,
    required Message localMessage,
    required ({String? receiverId, String? groupId}) target,
  }) async {
    if (_socketOutboundSender == null ||
        _socketClient == null ||
        !_socketClient.canSendBusinessMessage) {
      return false;
    }

    try {
      await _socketOutboundSender.sendTextMessage(
        chatId: localMessage.chatId,
        content: localMessage.content,
        clientMessageId: clientMessageId,
        receiverId: target.receiverId,
        groupId: target.groupId,
        messageType: 1, // TEXT
        extra: _buildWebSocketExtra(localMessage),
      );
      // 发送成功：更新消息状态为 sent
      _timelineController.markSentByClientMessageId(
        clientMessageId: clientMessageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: clientMessageId,
        status: MessageStatus.sent,
      );
      state = state.copyWith(pendingAction: ChatPendingAction.none);
      return true;
    } catch (e) {
      debugPrint('[ChatController] WebSocket send failed: $e');
      return false;
    }
  }

  Map<String, dynamic>? _buildWebSocketExtra(Message message) {
    final extra = <String, dynamic>{};
    final atUserIds = message.extra.atUserIds;
    if (atUserIds.isNotEmpty) {
      extra['atUserIds'] = atUserIds;
    }
    final mentions = message.extra.mentions;
    if (mentions.isNotEmpty) {
      extra['mentions'] = mentions.map((m) => m.toJson()).toList();
    }
    final quoteInfo = message.quoteInfo;
    if (quoteInfo != null) {
      extra['quoteInfo'] = quoteInfo.toJson();
    }
    return extra.isEmpty ? null : extra;
  }

  Future<bool> _submitTextMessageViaHttp(
    Message localMessage,
    String clientMessageId,
    ({String? receiverId, String? groupId}) target,
  ) async {
    await _sendMessageUseCase(
      chatId: localMessage.chatId,
      text: localMessage.content,
      clientMessageId: clientMessageId,
      receiverId: target.receiverId,
      groupId: target.groupId,
      quoteInfo: localMessage.quoteInfo,
      atUserIds: localMessage.extra.atUserIds,
      mentions: localMessage.extra.mentions,
    );
    // 发送成功：更新消息状态为 sent
    _timelineController.markSentByClientMessageId(
      clientMessageId: clientMessageId,
    );
    _conversationListController.patchLastMessageStatus(
      chatId: localMessage.chatId,
      messageId: clientMessageId,
      status: MessageStatus.sent,
    );
    state = state.copyWith(pendingAction: ChatPendingAction.none);
    return true;
  }

  ContactCardSharePayload? _restoreContactCardPayload(Message message) {
    final userId = message.extra.contactUserId?.trim() ?? '';
    final displayName = message.extra.contactDisplayName?.trim() ?? '';
    if (userId.isEmpty || displayName.isEmpty) {
      return null;
    }
    return ContactCardSharePayload(
      userId: userId,
      displayName: displayName,
      departmentName: message.extra.contactDepartmentName ?? '',
      postName: message.extra.contactPostName ?? '',
      avatar: message.extra.contactAvatar ?? '',
    );
  }

  bool _isContactCardMessage(Message message) {
    if (message.type == MessageType.contactCard) {
      return true;
    }
    return message.type == MessageType.custom &&
        (message.extra.customType?.trim().toUpperCase() ?? '') ==
            'CONTACT_CARD';
  }

  LocationSharePayload? _restoreLocationPayload(Message message) {
    final latitude = message.extra.locationLatitude;
    final longitude = message.extra.locationLongitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    return LocationSharePayload(
      name: message.extra.locationName ?? '',
      address: message.extra.locationAddress ?? message.content,
      latitude: latitude,
      longitude: longitude,
      provider: message.extra.locationProvider ?? '',
      poiId: message.extra.locationPoiId ?? '',
    );
  }

  StickerPayload? _restoreStickerPayload(Message message) {
    final url = (message.extra.fileUrl ?? message.content).trim();
    if (url.isEmpty) {
      return null;
    }
    return StickerPayload(
      stickerId: message.extra.stickerId?.trim().isNotEmpty == true
          ? message.extra.stickerId!.trim()
          : message.messageId,
      fileId: message.extra.fileId ?? '',
      url: url,
      thumbFileId: message.extra.thumbFileId,
      thumbUrl: message.extra.thumbnailUrl,
      md5: message.extra.md5,
      width: message.extra.width ?? 0,
      height: message.extra.height ?? 0,
      mimeType: message.extra.mimeType,
    );
  }

  Future<bool> _submitContactCardMessage(
    Message localMessage,
    ContactCardSharePayload payload,
  ) async {
    state = state.copyWith(
      pendingAction: ChatPendingAction.sendingMessage,
      error: null,
    );
    try {
      final target = _resolveLegacySendTarget();
      await _sendMessageUseCase.sendContactCard(
        chatId: localMessage.chatId,
        payload: payload,
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
        receiverId: target.receiverId,
        groupId: target.groupId,
      );
      // 发送成功：更新消息状态为 sent
      _timelineController.markSentByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.sent,
      );
      state = state.copyWith(pendingAction: ChatPendingAction.none);
      return true;
    } catch (error, stackTrace) {
      _timelineController.markFailedByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.failed,
      );
      state = state.copyWith(
        pendingAction: ChatPendingAction.none,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return false;
    }
  }

  Future<bool> _submitLocationMessage(
    Message localMessage,
    LocationSharePayload payload,
  ) async {
    state = state.copyWith(
      pendingAction: ChatPendingAction.sendingMessage,
      error: null,
    );
    try {
      final target = _resolveLegacySendTarget();
      await _sendMessageUseCase.sendLocation(
        chatId: localMessage.chatId,
        payload: payload,
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
        receiverId: target.receiverId,
        groupId: target.groupId,
      );
      // 发送成功：更新消息状态为 sent
      _timelineController.markSentByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.sent,
      );
      state = state.copyWith(pendingAction: ChatPendingAction.none);
      return true;
    } catch (error, stackTrace) {
      _timelineController.markFailedByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.failed,
      );
      state = state.copyWith(
        pendingAction: ChatPendingAction.none,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return false;
    }
  }

  Future<bool> _submitStickerMessage(
    Message localMessage,
    StickerPayload payload,
  ) async {
    state = state.copyWith(
      pendingAction: ChatPendingAction.sendingMessage,
      error: null,
    );
    try {
      final target = _resolveLegacySendTarget();
      await _sendMessageUseCase.sendSticker(
        chatId: localMessage.chatId,
        payload: payload,
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
        receiverId: target.receiverId,
        groupId: target.groupId,
      );
      // 发送成功：更新消息状态为 sent
      _timelineController.markSentByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.sent,
      );
      state = state.copyWith(pendingAction: ChatPendingAction.none);
      return true;
    } catch (error, stackTrace) {
      _timelineController.markFailedByClientMessageId(
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
      );
      _conversationListController.patchLastMessageStatus(
        chatId: localMessage.chatId,
        messageId: localMessage.clientMessageId ?? localMessage.messageId,
        status: MessageStatus.failed,
      );
      state = state.copyWith(
        pendingAction: ChatPendingAction.none,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return false;
    }
  }

  void _patchConversationForMessage(
    Message message, {
    required bool resetUnread,
  }) {
    _conversationListController.upsertLocalMessage(
      chatId: message.chatId,
      title: state.chatTitle ?? state.entryArgs.title ?? '',
      conversationType: state.entryArgs.conversationType,
      targetId: state.entryArgs.targetId,
      messageId: message.messageId,
      messageSequence: message.sequence,
      preview: _conversationPreview(message),
      messageType: message.type,
      senderName: message.senderName,
      isSelf: message.isOutgoing,
      customType: message.extra.customType,
      fileName: message.extra.fileName,
      systemEventKey: message.extra.systemEventKey,
      messageStatus: message.status,
      updatedAt: message.sentAt,
      resetUnread: resetUnread,
    );
  }

  ({String? receiverId, String? groupId}) _resolveLegacySendTarget() {
    if (state.entryArgs.conversationType == ConversationType.group) {
      final groupId = (state.entryArgs.targetId ?? state.entryArgs.chatId)
          .trim();
      return (
        receiverId: null,
        groupId: groupId.isEmpty || groupId == '0' ? null : groupId,
      );
    }
    final receiverId = (state.entryArgs.targetId ?? '').trim();
    return (
      receiverId: receiverId.isEmpty || receiverId == '0' ? null : receiverId,
      groupId: null,
    );
  }

  /// 检查网络是否可用
  bool _isNetworkAvailable() {
    return NetworkMonitorService().isNetworkAvailable;
  }

  String _conversationPreview(Message message) {
    return _messagePreviewFormatter(
      type: message.type,
      content: message.content,
      customType: message.extra.customType,
      fileName: message.extra.fileName,
      systemEventKey: message.extra.systemEventKey,
      conversationType: state.entryArgs.conversationType,
      isSelf: message.isOutgoing,
      senderName: message.senderName,
    );
  }
}
