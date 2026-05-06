import 'package:flutter/services.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_timeline_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_message_action.dart';

class ChatMessageActionResult {
  const ChatMessageActionResult({required this.noticeMessage});

  final String noticeMessage;
}

class ChatMessageActionController {
  const ChatMessageActionController(
    this._messageRepository,
    this._chatTimelineController,
  );

  final MessageRepository _messageRepository;
  final ChatTimelineController _chatTimelineController;

  Future<ChatMessageActionResult> handleAction({
    required ChatMessageAction action,
    required Message message,
    required String copiedNotice,
    required String favoritedNotice,
    required String deletedNotice,
  }) async {
    switch (action) {
      case ChatMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.content));
        return ChatMessageActionResult(noticeMessage: copiedNotice);
      case ChatMessageAction.quote:
        return const ChatMessageActionResult(noticeMessage: '');
      case ChatMessageAction.forward:
        return const ChatMessageActionResult(noticeMessage: '');
      case ChatMessageAction.favorite:
        await _messageRepository.addFavorite(messageId: message.messageId);
        return ChatMessageActionResult(noticeMessage: favoritedNotice);
      case ChatMessageAction.favoriteSticker:
        return const ChatMessageActionResult(noticeMessage: '');
      case ChatMessageAction.recall:
        return const ChatMessageActionResult(noticeMessage: '');
      case ChatMessageAction.delete:
        await _messageRepository.deleteMessage(messageId: message.messageId);
        _chatTimelineController.removeByAnyMessageId(message.messageId);
        return ChatMessageActionResult(noticeMessage: deletedNotice);
      case ChatMessageAction.multi:
        return const ChatMessageActionResult(noticeMessage: '');
    }
  }
}
