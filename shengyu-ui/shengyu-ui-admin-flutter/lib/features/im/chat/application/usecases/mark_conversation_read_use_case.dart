import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';

class MarkConversationReadUseCase {
  const MarkConversationReadUseCase(this._repository);

  final MessageRepository _repository;

  Future<void> call({required String chatId}) {
    return _repository.markConversationRead(chatId: chatId);
  }
}
