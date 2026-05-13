import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';

class MarkConversationReadUseCase {
  const MarkConversationReadUseCase(this._repository);

  final MessageRepository _repository;

  Future<void> call({required String chatId, required String readSequence}) {
    return _repository.markConversationRead(
      chatId: chatId,
      readSequence: readSequence,
    );
  }
}
