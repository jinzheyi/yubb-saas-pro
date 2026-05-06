import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task_status.dart';

class UploadTask {
  const UploadTask({
    required this.taskId,
    required this.purpose,
    required this.scope,
    required this.localUri,
    required this.displayName,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
    this.status = UploadTaskStatus.queued,
    this.progress = 0,
    this.uploadedFileId,
    this.uploadedUrl,
    this.checksum,
    this.errorMessage,
  });

  final String taskId;
  final UploadPurpose purpose;
  final UploadScope scope;
  final String localUri;
  final String displayName;
  final String mimeType;
  final int fileSize;
  final UploadTaskStatus status;
  final int progress;
  final String? uploadedFileId;
  final String? uploadedUrl;
  final String? checksum;
  final String? errorMessage;
  final DateTime createdAt;

  UploadTask copyWith({
    String? taskId,
    UploadPurpose? purpose,
    UploadScope? scope,
    String? localUri,
    String? displayName,
    String? mimeType,
    int? fileSize,
    UploadTaskStatus? status,
    int? progress,
    String? uploadedFileId,
    String? uploadedUrl,
    String? checksum,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return UploadTask(
      taskId: taskId ?? this.taskId,
      purpose: purpose ?? this.purpose,
      scope: scope ?? this.scope,
      localUri: localUri ?? this.localUri,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      uploadedFileId: uploadedFileId ?? this.uploadedFileId,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      checksum: checksum ?? this.checksum,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
