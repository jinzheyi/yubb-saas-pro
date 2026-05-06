import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_chat_window_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/load_older_messages_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
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
    state = state.copyWith(status: ChatTimelineStatus.loading, error: null);
    try {
      final viewportState = state.viewportState;
      final resolvedBeforeSequence = state.messages.isEmpty
          ? null
          : (state.messages.first.sequence?.trim().isNotEmpty == true
                ? state.messages.first.sequence
                : viewportState?.oldestSequence);
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
    final index = state.messages.indexWhere(
      (item) =>
          item.messageId == message.messageId ||
          (item.clientMessageId != null &&
              message.clientMessageId != null &&
              item.clientMessageId == message.clientMessageId) ||
          (item.sequence != null &&
              message.sequence != null &&
              item.sequence == message.sequence),
    );
    if (index >= 0) {
      final previous = state.messages[index];
      if (!_shouldMergeIncoming(previous, message)) {
        return;
      }
      final nextMessages = [...state.messages];
      nextMessages[index] = _mergeMessage(previous, message);
      state = state.copyWith(
        status: ChatTimelineStatus.ready,
        messages: nextMessages,
      );
      return;
    }

    state = state.copyWith(
      status: ChatTimelineStatus.ready,
      messages: [...state.messages, message],
    );
  }

  void replaceSingleMessage({
    required String clientMessageId,
    required Message message,
  }) {
    final index = state.messages.indexWhere(
      (item) =>
          item.clientMessageId == clientMessageId ||
          item.messageId == clientMessageId,
    );
    if (index < 0) {
      appendSingleMessage(message);
      return;
    }

    final nextMessages = [...state.messages];
    nextMessages[index] = _mergeMessage(nextMessages[index], message);
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
    final nextMessages = state.messages.map((item) {
      if (item.messageId != messageId) {
        return item;
      }
      return item.copyWith(status: MessageStatus.read);
    }).toList();
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
    return incoming
        .map((message) {
          final matched = _findMatchingMessage(existing, message);
          return matched == null ? message : _mergeMessage(matched, message);
        })
        .toList(growable: false);
  }

  List<Message> _mergeOlderMessages({
    required List<Message> existing,
    required List<Message> older,
  }) {
    if (older.isEmpty) {
      return existing;
    }
    final mergedOlder = _mergeWindowMessages(
      existing: existing,
      incoming: older,
    );
    final nextMessages = <Message>[...mergedOlder];
    for (final message in existing) {
      if (_findMatchingMessage(nextMessages, message) != null) {
        continue;
      }
      nextMessages.add(message);
    }
    return nextMessages;
  }

  Message? _findMatchingMessage(List<Message> items, Message target) {
    for (final item in items) {
      if (item.messageId.isNotEmpty && item.messageId == target.messageId) {
        return item;
      }
      if (item.clientMessageId != null &&
          target.clientMessageId != null &&
          item.clientMessageId == target.clientMessageId) {
        return item;
      }
      if (item.sequence != null &&
          target.sequence != null &&
          item.sequence == target.sequence) {
        return item;
      }
    }
    return null;
  }

  Message _mergeMessage(Message previous, Message next) {
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
        sentAt: previous.sentAt.millisecondsSinceEpoch > 0
            ? previous.sentAt
            : (finalMessage.sentAt.millisecondsSinceEpoch > 0
                  ? finalMessage.sentAt
                  : other.sentAt),
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
      sentAt: next.sentAt.millisecondsSinceEpoch > 0
          ? next.sentAt
          : previous.sentAt,
      isOutgoing: next.isOutgoing || previous.isOutgoing,
      clientMessageId: next.clientMessageId ?? previous.clientMessageId,
      sequence: _pickNonEmpty(next.sequence, previous.sequence),
      extra: _mergeExtra(previous, next),
    );
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

  dynamic _pickMeaningful(dynamic preferred, dynamic fallback) {
    if (preferred == null) {
      return fallback;
    }
    if (preferred is String) {
      final normalized = preferred.trim();
      if (normalized.isEmpty || normalized == '0' || normalized == 'null') {
        return fallback;
      }
    }
    return preferred;
  }

  dynamic _preferTrue(dynamic preferred, dynamic fallback) {
    if (preferred == true) {
      return true;
    }
    if (preferred != null) {
      return preferred;
    }
    return fallback;
  }

  dynamic _preferPositive(dynamic preferred, dynamic fallback) {
    if (preferred is num && preferred > 0) {
      return preferred;
    }
    if (preferred != null && preferred is! num) {
      return preferred;
    }
    return fallback;
  }

  dynamic _preferList(dynamic preferred, dynamic fallback) {
    if (preferred is List && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback ?? preferred;
  }

  dynamic _preferMentions(dynamic preferred, dynamic fallback) {
    if (preferred is List && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback ?? preferred;
  }

  dynamic _mergeExtra(Message previous, Message next) {
    return previous.extra.copyWith(
      revision: _pickNonEmpty(next.extra.revision, previous.extra.revision),
      localId: _pickNonEmpty(next.extra.localId, previous.extra.localId),
      localPath: _pickNonEmpty(next.extra.localPath, previous.extra.localPath),
      fileId: _pickNonEmpty(next.extra.fileId, previous.extra.fileId),
      fileUrl: _pickNonEmpty(next.extra.fileUrl, previous.extra.fileUrl),
      thumbnailUrl: _pickNonEmpty(
        next.extra.thumbnailUrl,
        previous.extra.thumbnailUrl,
      ),
      mimeType: _pickNonEmpty(next.extra.mimeType, previous.extra.mimeType),
      fileName: _pickNonEmpty(next.extra.fileName, previous.extra.fileName),
      fileType: _pickNonEmpty(next.extra.fileType, previous.extra.fileType),
      fileSize:
          _preferPositive(next.extra.fileSize, previous.extra.fileSize) as int?,
      width: _preferPositive(next.extra.width, previous.extra.width) as int?,
      height: _preferPositive(next.extra.height, previous.extra.height) as int?,
      duration:
          _preferPositive(next.extra.duration, previous.extra.duration) as int?,
      durationMs:
          _preferPositive(next.extra.durationMs, previous.extra.durationMs)
              as int?,
      voicePlayed:
          _preferTrue(next.extra.voicePlayed, previous.extra.voicePlayed)
              as bool?,
      md5: _pickNonEmpty(next.extra.md5, previous.extra.md5),
      customType: _pickNonEmpty(
        next.extra.customType,
        previous.extra.customType,
      ),
      contactUserId: _pickNonEmpty(
        next.extra.contactUserId,
        previous.extra.contactUserId,
      ),
      contactDisplayName: _pickNonEmpty(
        next.extra.contactDisplayName,
        previous.extra.contactDisplayName,
      ),
      contactDepartmentName: _pickNonEmpty(
        next.extra.contactDepartmentName,
        previous.extra.contactDepartmentName,
      ),
      contactPostName: _pickNonEmpty(
        next.extra.contactPostName,
        previous.extra.contactPostName,
      ),
      contactAvatar: _pickNonEmpty(
        next.extra.contactAvatar,
        previous.extra.contactAvatar,
      ),
      locationName: _pickNonEmpty(
        next.extra.locationName,
        previous.extra.locationName,
      ),
      locationAddress: _pickNonEmpty(
        next.extra.locationAddress,
        previous.extra.locationAddress,
      ),
      locationLatitude:
          _preferPositive(
                next.extra.locationLatitude,
                previous.extra.locationLatitude,
              )
              as double?,
      locationLongitude:
          _preferPositive(
                next.extra.locationLongitude,
                previous.extra.locationLongitude,
              )
              as double?,
      locationProvider: _pickNonEmpty(
        next.extra.locationProvider,
        previous.extra.locationProvider,
      ),
      locationPoiId: _pickNonEmpty(
        next.extra.locationPoiId,
        previous.extra.locationPoiId,
      ),
      quoteMessageId:
          _pickMeaningful(
                next.extra.quoteMessageId,
                previous.extra.quoteMessageId,
              )
              as String?,
      quoteContent:
          _pickMeaningful(next.extra.quoteContent, previous.extra.quoteContent)
              as String?,
      quoteSenderName:
          _pickMeaningful(
                next.extra.quoteSenderName,
                previous.extra.quoteSenderName,
              )
              as String?,
      forwardedFrom:
          _pickMeaningful(
                next.extra.forwardedFrom,
                previous.extra.forwardedFrom,
              )
              as String?,
      atUserIds:
          (_preferList(next.extra.atUserIds, previous.extra.atUserIds)
              as List<String>?) ??
          const <String>[],
      mentions:
          (_preferMentions(next.extra.mentions, previous.extra.mentions)
                  as List?)
              ?.cast() ??
          const [],
      reeditContent:
          _pickMeaningful(
                next.extra.reeditContent,
                previous.extra.reeditContent,
              )
              as String?,
      reeditDeadlineTs:
          _preferPositive(
                next.extra.reeditDeadlineTs,
                previous.extra.reeditDeadlineTs,
              )
              as int?,
      systemEventKey:
          _pickMeaningful(
                next.extra.systemEventKey,
                previous.extra.systemEventKey,
              )
              as String?,
    );
  }
}
