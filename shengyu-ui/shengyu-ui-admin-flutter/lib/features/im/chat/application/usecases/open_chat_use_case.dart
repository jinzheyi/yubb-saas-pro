import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/open_chat_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';

class OpenChatUseCase {
  const OpenChatUseCase(this._messageRepository, this._conversationRepository);

  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;

  Future<OpenChatResult> call(OpenChatCommand command) async {
    final conversations = await _conversationRepository.getConversationList();
    String chatTitle = _resolveFallbackTitle(command);
    for (final conversation in conversations) {
      if (conversation.chatId == command.chatId) {
        chatTitle = conversation.title;
        break;
      }
    }
    final window = await _messageRepository.getMessageWindow(command);
    return OpenChatResult(chatTitle: chatTitle, window: window);
  }

  String _resolveFallbackTitle(OpenChatCommand command) {
    final title = command.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return command.chatId;
  }
}
