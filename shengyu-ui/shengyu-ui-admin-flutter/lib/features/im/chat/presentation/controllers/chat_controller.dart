import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/optimistic_message_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/mark_conversation_read_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/open_chat_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_receipt_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_page_state.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/services/message_preview_formatter.dart';

class ChatController extends StateNotifier<ChatPageState> {
  ChatController(
    this._openChatUseCase,
    this._sendMessageUseCase,
    this._markConversationReadUseCase,
    this._optimisticMessageFactory,
    this._messagePreviewFormatter,
    this._conversationListController,
    this._timelineController,
    this._receiptController,
  ) : super(const ChatPageState(entryArgs: ChatEntryArgs.empty()));

  final OpenChatUseCase _openChatUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkConversationReadUseCase _markConversationReadUseCase;
  final OptimisticMessageFactory _optimisticMessageFactory;
  final MessagePreviewFormatter _messagePreviewFormatter;
  final ConversationListController _conversationListController;
  final ChatTimelineController _timelineController;
  final ChatReceiptController _receiptController;

  Future<void> initialize(ChatEntryArgs args) async {
    state = state.copyWith(
      entryArgs: args,
      pageStatus: ChatPageStatus.initializing,
      error: null,
    );

    try {
      final result = await _openChatUseCase(OpenChatCommand.fromArgs(args));
      _timelineController.applyWindow(result.window);
      _receiptController.markVisible(args.chatId);
      await _markConversationReadUseCase(chatId: args.chatId);
      _conversationListController.markConversationRead(args.chatId);
      state = state.copyWith(
        pageStatus: ChatPageStatus.ready,
        chatTitle: result.chatTitle,
        isReadOnly: args.isReadOnly,
        highlightedMessageId: args.highlightedMessageId,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        pageStatus: ChatPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
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
    _conversationListController.upsertLocalMessage(
      chatId: localMessage.chatId,
      title: state.chatTitle ?? state.entryArgs.title ?? '',
      conversationType: state.entryArgs.conversationType,
      messageId: localMessage.clientMessageId ?? localMessage.messageId,
      messageSequence: localMessage.sequence,
      preview: _conversationPreview(localMessage),
      messageType: localMessage.type,
      messageStatus: localMessage.status,
      updatedAt: localMessage.sentAt,
      resetUnread: true,
    );
    state = state.copyWith(
      pendingAction: ChatPendingAction.sendingMessage,
      error: null,
    );

    try {
      final target = _resolveLegacySendTarget();
      await _sendMessageUseCase(
        chatId: localMessage.chatId,
        text: localMessage.content,
        clientMessageId: localMessage.clientMessageId ?? localMessage.messageId,
        receiverId: target.receiverId,
        groupId: target.groupId,
        quoteInfo: localMessage.quoteInfo,
        atUserIds: localMessage.extra.atUserIds,
        mentions: localMessage.extra.mentions,
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
    _conversationListController.upsertLocalMessage(
      chatId: localMessage.chatId,
      title: state.chatTitle ?? state.entryArgs.title ?? '',
      conversationType: state.entryArgs.conversationType,
      messageId: localMessage.clientMessageId ?? localMessage.messageId,
      messageSequence: localMessage.sequence,
      preview: _conversationPreview(localMessage),
      messageType: localMessage.type,
      messageStatus: localMessage.status,
      updatedAt: localMessage.sentAt,
      resetUnread: true,
    );
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
    _conversationListController.upsertLocalMessage(
      chatId: localMessage.chatId,
      title: state.chatTitle ?? state.entryArgs.title ?? '',
      conversationType: state.entryArgs.conversationType,
      messageId: localMessage.clientMessageId ?? localMessage.messageId,
      messageSequence: localMessage.sequence,
      preview: _conversationPreview(localMessage),
      messageType: localMessage.type,
      messageStatus: localMessage.status,
      updatedAt: localMessage.sentAt,
      resetUnread: true,
    );
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
    _conversationListController.upsertLocalMessage(
      chatId: localMessage.chatId,
      title: state.chatTitle ?? state.entryArgs.title ?? '',
      conversationType: state.entryArgs.conversationType,
      messageId: localMessage.clientMessageId ?? localMessage.messageId,
      messageSequence: localMessage.sequence,
      preview: _conversationPreview(localMessage),
      messageType: localMessage.type,
      messageStatus: localMessage.status,
      updatedAt: localMessage.sentAt,
      resetUnread: true,
    );
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
      messageId: message.messageId,
      messageSequence: message.sequence,
      preview: _conversationPreview(message),
      messageType: message.type,
      messageStatus: message.status,
      updatedAt: message.sentAt,
      resetUnread: resetUnread,
    );
  }

  ({String? receiverId, String? groupId}) _resolveLegacySendTarget() {
    if (state.entryArgs.conversationType == ConversationType.group) {
      final groupId = (state.entryArgs.targetId ?? state.entryArgs.chatId).trim();
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

  String _conversationPreview(Message message) {
    return _messagePreviewFormatter.formatConversationPreview(
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
