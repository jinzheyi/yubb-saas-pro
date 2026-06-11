import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/services/message_semantics_normalizer.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_chat_window_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_older_messages_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/chat_timeline_state.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class ChatTimelineController extends StateNotifier<ChatTimelineState> {
  ChatTimelineController(
    this._loadChatWindowUseCase,
    this._loadOlderMessagesUseCase,
  ) : super(const ChatTimelineState());

  final LoadChatWindowUseCase _loadChatWindowUseCase;
  final LoadOlderMessagesUseCase _loadOlderMessagesUseCase;

  void applyWindow(ChatWindowResult result) {
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: _mergeWindowMessages(
        existing: state.messages,
        incoming: result.messages,
      ),
      viewportState: result.viewportState,
      error: null,
    );
  }

  Future<void> loadOlder({required String chatId}) async {
    // 如果没有更多历史消息，直接返回
    if (state.viewportState?.hasMoreBefore == false) {
      return;
    }
    
    state = state.copyWith(status: ChatTimelineStatus.loading, error: null);
    try {
      final viewportState = state.viewportState;
      
      // 优先使用第一条消息的sequence
      String? resolvedBeforeSequence;
      if (state.messages.isNotEmpty) {
        final firstMessage = state.messages.first;
        if (firstMessage.sequence?.trim().isNotEmpty == true) {
          resolvedBeforeSequence = firstMessage.sequence;
        }
      }
      
      // 如果第一条消息没有sequence，使用viewportState的oldestSequence
      if (resolvedBeforeSequence == null || resolvedBeforeSequence.trim().isEmpty) {
        resolvedBeforeSequence = viewportState?.oldestSequence;
      }
      
      // 如果仍然没有有效的beforeSequence，说明没有更多消息
      if (resolvedBeforeSequence == null || 
          resolvedBeforeSequence.trim().isEmpty || 
          resolvedBeforeSequence == '0') {
        state = state.copyWith(
          status: ChatTimelineStatus.ready,
          viewportState: viewportState?.copyWith(hasMoreBefore: false),
        );
        return;
      }
      
      final result = await _loadOlderMessagesUseCase(
        chatId: chatId,
        beforeSequence: resolvedBeforeSequence,
      );
      state = state.copyWith(
        status: ChatTimelineStatus.ready,
        messages: _mergeOlderMessages(
          existing: state.messages,
          older: result.messages,
        ),
        viewportState: result.viewportState,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: ChatTimelineStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  void appendMessage(ChatWindowResult result) {
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: _mergeWindowMessages(
        existing: state.messages,
        incoming: result.messages,
      ),
      viewportState: result.viewportState,
    );
  }

  Future<void> reloadLatest({required OpenChatCommand command}) async {
    try {
      final result = await _loadChatWindowUseCase(command);
      state = state.copyWith(
        status: ChatTimelineStatus.ready,
        messages: _mergeWindowMessages(
          existing: state.messages,
          incoming: result.messages,
        ),
        viewportState: result.viewportState,
        error: null,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: ChatTimelineStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  void appendSingleMessage(Message message) {
    final normalizedMessage = MessageSemanticsNormalizer.normalize(message);
    final index = state.messages.indexWhere(
      (item) => _isSameMessage(item, normalizedMessage),
    );
    if (index >= 0) {
      final previous = state.messages[index];
      if (!_shouldMergeIncoming(previous, normalizedMessage)) {
        return;
      }
      final nextMessages = [...state.messages];
      nextMessages[index] = _mergeMessage(previous, normalizedMessage);
      state = state.copyWith(
        status: ChatTimelineStatus.ready,
        messages: nextMessages,
      );
      return;
    }

    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: [...state.messages, normalizedMessage],
    );
  }

  void replaceSingleMessage({
    required String clientMessageId,
    required Message message,
  }) {
    final normalizedMessage = MessageSemanticsNormalizer.normalize(message);
    final index = state.messages.indexWhere(
      (item) =>
          item.clientMessageId == clientMessageId ||
          item.messageId == clientMessageId,
    );
    if (index < 0) {
      appendSingleMessage(normalizedMessage);
      return;
    }

    final nextMessages = [...state.messages];
    nextMessages[index] = _mergeMessage(nextMessages[index], normalizedMessage);
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
      error: null,
    );
  }

  void markFailedByClientMessageId({required String clientMessageId}) {
    final index = state.messages.indexWhere(
      (item) =>
          item.clientMessageId == clientMessageId ||
          item.messageId == clientMessageId,
    );
    if (index < 0) {
      return;
    }

    final nextMessages = [...state.messages];
    nextMessages[index] = nextMessages[index].copyWith(
      status: MessageStatus.failed,
    );
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
    );
  }

  void markSendingByClientMessageId({required String clientMessageId}) {
    final index = state.messages.indexWhere(
      (item) =>
          item.clientMessageId == clientMessageId ||
          item.messageId == clientMessageId,
    );
    if (index < 0) {
      return;
    }

    final nextMessages = [...state.messages];
    nextMessages[index] = nextMessages[index].copyWith(
      status: MessageStatus.sending,
    );
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
    );
  }

  Message? findByAnyMessageId(String messageId) {
    for (final item in state.messages) {
      if (item.messageId == messageId || item.clientMessageId == messageId) {
        return item;
      }
    }
    return null;
  }

  void applyReadReceipt({required String messageId}) {
    final index = state.messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return;
    }
    final target = state.messages[index];
    if (target.status == MessageStatus.read) {
      return;
    }
    final nextMessages = [...state.messages];
    nextMessages[index] = target.copyWith(status: MessageStatus.read);
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
    );
  }

  void markVoicePlayed({required String messageId}) {
    final index = state.messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return;
    }
    final target = state.messages[index];
    final nextMessages = [...state.messages];
    nextMessages[index] = target.copyWith(
      extra: target.extra.copyWith(voicePlayed: true),
    );
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
      error: null,
    );
  }

  void applyRecalledMessage(Message message) {
    final index = state.messages.indexWhere(
      (item) =>
          item.messageId == message.messageId ||
          (item.clientMessageId != null &&
              message.clientMessageId != null &&
              item.clientMessageId == message.clientMessageId),
    );
    if (index < 0) {
      appendSingleMessage(message);
      return;
    }
    final previous = state.messages[index];
    final nextMessages = [...state.messages];
    nextMessages[index] = previous.copyWith(
      type: message.type,
      status: message.status,
      content: message.content,
      sentAt: previous.sentAt,
      senderId: previous.senderId.isEmpty
          ? message.senderId
          : previous.senderId,
      senderName: previous.senderName.isEmpty
          ? message.senderName
          : previous.senderName,
      isOutgoing: previous.isOutgoing || message.isOutgoing,
      sequence: previous.sequence != null && previous.sequence!.isNotEmpty
          ? previous.sequence
          : message.sequence,
      extra: previous.extra.copyWith(
        customType: message.extra.customType?.trim().isNotEmpty == true
            ? message.extra.customType
            : previous.extra.customType,
        quoteMessageId: message.extra.quoteMessageId?.trim().isNotEmpty == true
            ? message.extra.quoteMessageId
            : previous.extra.quoteMessageId,
        quoteContent: message.extra.quoteContent?.trim().isNotEmpty == true
            ? message.extra.quoteContent
            : previous.extra.quoteContent,
        quoteSenderName:
            message.extra.quoteSenderName?.trim().isNotEmpty == true
            ? message.extra.quoteSenderName
            : previous.extra.quoteSenderName,
        forwardedFrom: message.extra.forwardedFrom?.trim().isNotEmpty == true
            ? message.extra.forwardedFrom
            : previous.extra.forwardedFrom,
        reeditContent: message.extra.reeditContent?.trim().isNotEmpty == true
            ? message.extra.reeditContent
            : previous.extra.reeditContent,
        reeditDeadlineTs: (message.extra.reeditDeadlineTs ?? 0) > 0
            ? message.extra.reeditDeadlineTs
            : previous.extra.reeditDeadlineTs,
      ),
    );
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
      error: null,
    );
  }

  void removeByAnyMessageId(String messageId) {
    final nextMessages = state.messages
        .where(
          (item) =>
              item.messageId != messageId && item.clientMessageId != messageId,
        )
        .toList();
    if (nextMessages.length == state.messages.length) {
      return;
    }
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
      error: null,
    );
  }

  void applyReeditHint({
    required String messageId,
    required String content,
    required int deadlineTs,
  }) {
    if (messageId.trim().isEmpty || content.trim().isEmpty || deadlineTs <= 0) {
      return;
    }
    final index = state.messages.indexWhere(
      (item) =>
          item.messageId == messageId || item.clientMessageId == messageId,
    );
    if (index < 0) {
      return;
    }
    final target = state.messages[index];
    if (!_isRecalledFinal(target)) {
      return;
    }
    final nextMessages = [...state.messages];
    nextMessages[index] = target.copyWith(
      extra: target.extra.copyWith(
        reeditContent: content,
        reeditDeadlineTs: deadlineTs,
      ),
    );
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: nextMessages,
      error: null,
    );
  }

  void clearAll() {
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: const <Message>[],
      error: null,
    );
  }

  void replaceAllMessages(List<Message> messages) {
    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: _mergeWindowMessages(
        existing: state.messages,
        incoming: messages,
      ),
      error: null,
    );
  }

  List<Message> _mergeWindowMessages({
    required List<Message> existing,
    required List<Message> incoming,
  }) {
    if (existing.isEmpty || incoming.isEmpty) {
      return incoming;
    }

    // 构建哈希索引表，将查找复杂度从 O(n) 降至 O(1)
    final existingIndex = <String, Message>{};
    for (final item in existing) {
      if (item.messageId.isNotEmpty) {
        existingIndex[item.messageId] = item;
      }
      final cid = item.clientMessageId;
      if (cid != null && cid.isNotEmpty) {
        existingIndex[cid] = item;
      }
    }

    final result = <Message>[];
    for (final message in incoming) {
      final matched = _findMatchedByHash(message, existingIndex);
      result.add(matched == null ? message : _mergeMessage(matched, message));
    }
    return result;
  }

  List<Message> _mergeOlderMessages({
    required List<Message> existing,
    required List<Message> older,
  }) {
    if (older.isEmpty) {
      return existing;
    }

    // 构建 older 消息的哈希索引
    final olderIndex = <String, Message>{};
    for (final item in older) {
      if (item.messageId.isNotEmpty) {
        olderIndex[item.messageId] = item;
      }
      final cid = item.clientMessageId;
      if (cid != null && cid.isNotEmpty) {
        olderIndex[cid] = item;
      }
    }

    // 1. 合并 older 消息（用 existing 中的匹配项增强）
    final existingIndex = <String, Message>{};
    for (final item in existing) {
      if (item.messageId.isNotEmpty) {
        existingIndex[item.messageId] = item;
      }
      final cid = item.clientMessageId;
      if (cid != null && cid.isNotEmpty) {
        existingIndex[cid] = item;
      }
    }

    final mergedOlder = <Message>[];
    for (final message in older) {
      final matched = _findMatchedByHash(message, existingIndex);
      mergedOlder.add(matched == null ? message : _mergeMessage(matched, message));
    }

    // 2. 追加 existing 中未匹配的消息（使用 olderIndex O(1) 查找）
    final nextMessages = <Message>[...mergedOlder];
    for (final message in existing) {
      if (_findMatchedByHash(message, olderIndex) != null) {
        continue;
      }
      nextMessages.add(message);
    }
    return nextMessages;
  }

  /// 通过哈希索引表快速查找匹配消息（O(1) 复杂度）
  Message? _findMatchedByHash(
    Message target,
    Map<String, Message> index,
  ) {
    if (target.messageId.isNotEmpty) {
      final matched = index[target.messageId];
      if (matched != null && _isSameMessage(matched, target)) {
        return matched;
      }
    }
    final cid = target.clientMessageId;
    if (cid != null && cid.isNotEmpty) {
      final matched = index[cid];
      if (matched != null && _isSameMessage(matched, target)) {
        return matched;
      }
    }
    // 序列号匹配（兜底）
    final seq = target.sequence;
    if (seq != null && seq.isNotEmpty) {
      final matched = index[seq];
      if (matched != null && _isSameMessage(matched, target)) {
        return matched;
      }
    }
    return null;
  }

  bool _isSameMessage(Message previous, Message next) {
    if (previous.messageId.isNotEmpty && previous.messageId == next.messageId) {
      return true;
    }
    if (previous.clientMessageId != null &&
        next.clientMessageId != null &&
        previous.clientMessageId == next.clientMessageId) {
      return true;
    }
    if (previous.sequence != null &&
        next.sequence != null &&
        previous.sequence == next.sequence) {
      return true;
    }
    return _isLikelySameOutgoingMediaMessage(previous, next);
  }

  bool _isLikelySameOutgoingMediaMessage(Message previous, Message next) {
    if (!previous.isOutgoing || !next.isOutgoing) {
      return false;
    }
    if (previous.chatId.trim() != next.chatId.trim()) {
      return false;
    }
    if (previous.type != next.type || !_isMediaLike(previous.type)) {
      return false;
    }
    final previousFileId = previous.extra.fileId?.trim() ?? '';
    final nextFileId = next.extra.fileId?.trim() ?? '';
    if (previousFileId.isNotEmpty &&
        nextFileId.isNotEmpty &&
        previousFileId == nextFileId) {
      return true;
    }
    final previousUrl = _normalizedMediaUrl(previous);
    final nextUrl = _normalizedMediaUrl(next);
    if (previousUrl.isEmpty || nextUrl.isEmpty || previousUrl != nextUrl) {
      return false;
    }
    final deltaSeconds = previous.sentAt
        .difference(next.sentAt)
        .inSeconds
        .abs();
    return deltaSeconds <= 120;
  }

  bool _isMediaLike(MessageType type) {
    return type == MessageType.image ||
        type == MessageType.video ||
        type == MessageType.file ||
        type == MessageType.sticker;
  }

  String _normalizedMediaUrl(Message message) {
    final fileUrl = message.extra.fileUrl?.trim() ?? '';
    if (fileUrl.isNotEmpty && !fileUrl.startsWith('blob:')) {
      return fileUrl;
    }
    final thumbnailUrl = message.extra.thumbnailUrl?.trim() ?? '';
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('blob:')) {
      return thumbnailUrl;
    }
    final content = message.content.trim();
    if (content.isNotEmpty && !content.startsWith('blob:')) {
      return content;
    }
    return '';
  }

  Message _mergeMessage(Message previous, Message next) {
    previous = MessageSemanticsNormalizer.normalize(previous);
    next = MessageSemanticsNormalizer.normalize(next);
    final resolvedType = _resolveMergedType(previous, next);
    final resolvedStatus = _resolveMergedStatus(previous, next, resolvedType);
    final resolvedContent = _resolveMergedContent(previous, next, resolvedType);
    if (_isRecalledFinal(previous) || _isRecalledFinal(next)) {
      final finalMessage = _isRecalledFinal(next) ? next : previous;
      final other = identical(finalMessage, next) ? previous : next;
      return finalMessage.copyWith(
        messageId: finalMessage.messageId.isNotEmpty
            ? finalMessage.messageId
            : other.messageId,
        chatId: finalMessage.chatId.isNotEmpty
            ? finalMessage.chatId
            : other.chatId,
        senderId: finalMessage.senderId.isNotEmpty
            ? finalMessage.senderId
            : other.senderId,
        senderName: finalMessage.senderName.isNotEmpty
            ? finalMessage.senderName
            : other.senderName,
        senderAvatar: finalMessage.senderAvatar?.isNotEmpty == true
            ? finalMessage.senderAvatar
            : (other.senderAvatar?.isNotEmpty == true
                  ? other.senderAvatar
                  : null),
        sentAt: previous.sentAt.millisecondsSinceEpoch > 0
            ? previous.sentAt
            : (finalMessage.sentAt.millisecondsSinceEpoch > 0
                  ? finalMessage.sentAt
                  : other.sentAt),
        type: resolvedType,
        status: resolvedStatus,
        content: resolvedContent,
        isOutgoing: finalMessage.isOutgoing || other.isOutgoing,
        clientMessageId: finalMessage.clientMessageId ?? other.clientMessageId,
        sequence: _pickNonEmpty(finalMessage.sequence, other.sequence),
        extra: _mergeExtra(previous, next),
      );
    }
    return next.copyWith(
      messageId: next.messageId.isNotEmpty
          ? next.messageId
          : previous.messageId,
      chatId: next.chatId.isNotEmpty ? next.chatId : previous.chatId,
      senderId: next.senderId.isNotEmpty ? next.senderId : previous.senderId,
      senderName: next.senderName.isNotEmpty
          ? next.senderName
          : previous.senderName,
      senderAvatar: next.senderAvatar?.isNotEmpty == true
          ? next.senderAvatar
          : (previous.senderAvatar?.isNotEmpty == true
                ? previous.senderAvatar
                : null),
      sentAt: next.sentAt.millisecondsSinceEpoch > 0
          ? next.sentAt
          : previous.sentAt,
      type: resolvedType,
      status: resolvedStatus,
      content: resolvedContent,
      isOutgoing: next.isOutgoing || previous.isOutgoing,
      clientMessageId: next.clientMessageId ?? previous.clientMessageId,
      sequence: _pickNonEmpty(next.sequence, previous.sequence),
      extra: _mergeExtra(previous, next),
    );
  }

  MessageType _resolveMergedType(Message previous, Message next) {
    if (next.type == MessageType.text &&
        previous.type != MessageType.text &&
        next.content.trim().isEmpty &&
        _hasMediaIdentity(previous)) {
      return previous.type;
    }
    return next.type;
  }

  MessageStatus _resolveMergedStatus(
    Message previous,
    Message next,
    MessageType resolvedType,
  ) {
    if (resolvedType == MessageType.voice &&
        previous.status == MessageStatus.sending &&
        next.status == MessageStatus.sending &&
        _hasMediaIdentity(previous)) {
      return MessageStatus.sent;
    }
    return next.status;
  }

  String _resolveMergedContent(
    Message previous,
    Message next,
    MessageType resolvedType,
  ) {
    if (resolvedType == MessageType.voice) {
      return '';
    }
    if (next.content.trim().isEmpty && previous.content.trim().isNotEmpty) {
      return previous.content;
    }
    return next.content;
  }

  bool _hasMediaIdentity(Message message) {
    return (message.extra.fileId?.trim().isNotEmpty ?? false) ||
        (message.extra.localPath?.trim().isNotEmpty ?? false) ||
        (message.extra.durationMs ?? 0) > 0 ||
        (message.extra.duration ?? 0) > 0;
  }

  bool _shouldMergeIncoming(Message previous, Message next) {
    if (_isRecalledFinal(next)) {
      return true;
    }
    final previousRevision = previous.extra.revision?.trim() ?? '';
    final nextRevision = next.extra.revision?.trim() ?? '';
    if (previousRevision.isEmpty || nextRevision.isEmpty) {
      return true;
    }
    return _compareRevision(nextRevision, previousRevision) > 0;
  }

  int _compareRevision(String left, String right) {
    final leftInt = BigInt.tryParse(left);
    final rightInt = BigInt.tryParse(right);
    if (leftInt != null && rightInt != null) {
      return leftInt.compareTo(rightInt);
    }
    return left.compareTo(right);
  }

  bool _isRecalledFinal(Message message) {
    if (message.status == MessageStatus.recalled) {
      return true;
    }
    if (message.type != MessageType.system) {
      return false;
    }
    final text = message.content.trim().toLowerCase();
    if (text.isEmpty) {
      return false;
    }
    return text.contains('撤回') || text.contains('recalled');
  }

  T? _pickNonEmpty<T>(T? preferred, T? fallback) {
    if (preferred == null) {
      return fallback;
    }
    if (preferred is String && preferred.trim().isEmpty) {
      return fallback;
    }
    return preferred;
  }

  String? _pickMeaningfulString(String? preferred, String? fallback) {
    if (preferred == null) {
      return fallback;
    }
    final normalized = preferred.trim();
    if (normalized.isEmpty || normalized == '0' || normalized == 'null') {
      return fallback;
    }
    return preferred;
  }

  T? _preferTrue<T>(T? preferred, T? fallback) {
    if (preferred == true) {
      return preferred;
    }
    if (preferred != null) {
      return preferred;
    }
    return fallback;
  }

  T? _preferPositive<T>(T? preferred, T? fallback) {
    if (preferred is num && preferred > 0) {
      return preferred;
    }
    if (preferred != null && preferred is! num) {
      return preferred;
    }
    return fallback;
  }

  List<T>? _preferList<T>(List<T>? preferred, List<T>? fallback) {
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback ?? preferred;
  }

  List<T>? _preferMentions<T>(List<T>? preferred, List<T>? fallback) {
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback ?? preferred;
  }

  MessageExtra _mergeExtra(Message previous, Message next) {
    final p = previous.extra;
    final n = next.extra;
    return p.copyWith(
      revision: _pickNonEmpty(n.revision, p.revision),
      localId: _pickNonEmpty(n.localId, p.localId),
      localPath: _pickNonEmpty(n.localPath, p.localPath),
      fileId: _pickNonEmpty(n.fileId, p.fileId),
      fileUrl: _pickNonEmpty(n.fileUrl, p.fileUrl),
      thumbnailUrl: _pickNonEmpty(n.thumbnailUrl, p.thumbnailUrl),
      mimeType: _pickNonEmpty(n.mimeType, p.mimeType),
      fileName: _pickNonEmpty(n.fileName, p.fileName),
      fileType: _pickNonEmpty(n.fileType, p.fileType),
      fileSize: _preferPositive(n.fileSize, p.fileSize),
      width: _preferPositive(n.width, p.width),
      height: _preferPositive(n.height, p.height),
      duration: _preferPositive(n.duration, p.duration),
      durationMs: _preferPositive(n.durationMs, p.durationMs),
      voicePlayed: _preferTrue(n.voicePlayed, p.voicePlayed),
      md5: _pickNonEmpty(n.md5, p.md5),
      customType: _pickNonEmpty(n.customType, p.customType),
      contactUserId: _pickNonEmpty(n.contactUserId, p.contactUserId),
      contactDisplayName: _pickNonEmpty(
        n.contactDisplayName,
        p.contactDisplayName,
      ),
      contactDepartmentName: _pickNonEmpty(
        n.contactDepartmentName,
        p.contactDepartmentName,
      ),
      contactPostName: _pickNonEmpty(n.contactPostName, p.contactPostName),
      contactAvatar: _pickNonEmpty(n.contactAvatar, p.contactAvatar),
      locationName: _pickNonEmpty(n.locationName, p.locationName),
      locationAddress: _pickNonEmpty(n.locationAddress, p.locationAddress),
      locationLatitude: _preferPositive(n.locationLatitude, p.locationLatitude),
      locationLongitude: _preferPositive(
        n.locationLongitude,
        p.locationLongitude,
      ),
      locationProvider: _pickNonEmpty(n.locationProvider, p.locationProvider),
      locationPoiId: _pickNonEmpty(n.locationPoiId, p.locationPoiId),
      quoteMessageId: _pickMeaningfulString(
        n.quoteMessageId,
        p.quoteMessageId,
      ),
      quoteContent: _pickMeaningfulString(n.quoteContent, p.quoteContent),
      quoteSenderName: _pickMeaningfulString(
        n.quoteSenderName,
        p.quoteSenderName,
      ),
      forwardedFrom: _pickMeaningfulString(n.forwardedFrom, p.forwardedFrom),
      atUserIds: _preferList(n.atUserIds, p.atUserIds) ?? const <String>[],
      mentions: _preferMentions(n.mentions, p.mentions) ?? const [],
      reeditContent: _pickMeaningfulString(n.reeditContent, p.reeditContent),
      reeditDeadlineTs: _preferPositive(
        n.reeditDeadlineTs,
        p.reeditDeadlineTs,
      ),
      systemEventKey: _pickMeaningfulString(n.systemEventKey, p.systemEventKey),
    );
  }
}
