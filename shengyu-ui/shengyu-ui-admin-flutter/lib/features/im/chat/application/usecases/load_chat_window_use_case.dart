import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';

class LoadChatWindowUseCase {
  const LoadChatWindowUseCase(this._repository);

  final MessageRepository _repository;

  Future<ChatWindowResult> call(OpenChatCommand command) {
    return _repository.getMessageWindow(command);
  }
}
