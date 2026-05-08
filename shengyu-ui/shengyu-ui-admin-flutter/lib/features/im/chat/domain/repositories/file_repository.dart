import 'dart:typed_data';

import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';

abstract class FileRepository {
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
    Uint8List? bytes,
    int? maxSize,
  });

  Future<FilePreviewDescriptor> getFilePreviewDescriptor(FilePreviewArgs args);

  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = 600,
  });
}
