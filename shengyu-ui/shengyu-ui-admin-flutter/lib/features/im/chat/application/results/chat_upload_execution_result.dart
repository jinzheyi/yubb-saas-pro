import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task.dart';

class ChatUploadExecutionResult {
  const ChatUploadExecutionResult({required this.task, required this.message});

  final UploadTask task;
  final Message message;
}
