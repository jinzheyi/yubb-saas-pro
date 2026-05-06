import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/uploaded_file.dart';

class UploadResult {
  const UploadResult({
    required this.taskId,
    required this.purpose,
    required this.scope,
    required this.file,
  });

  final String taskId;
  final UploadPurpose purpose;
  final UploadScope scope;
  final UploadedFile file;
}
