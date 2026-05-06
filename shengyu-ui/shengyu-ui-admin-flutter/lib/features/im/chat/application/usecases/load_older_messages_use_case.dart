import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';

class LoadOlderMessagesUseCase {
  const LoadOlderMessagesUseCase(this._repository);

  final MessageRepository _repository;

  Future<ChatWindowResult> call({
    required String chatId,
    required String? beforeSequence,
  }) {
    return _repository.getOlderMessages(
      chatId: chatId,
      beforeSequence: beforeSequence,
    );
  }
}
