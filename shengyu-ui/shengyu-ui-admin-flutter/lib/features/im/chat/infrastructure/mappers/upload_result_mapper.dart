import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/uploaded_file.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_and_create_file_response_dto.dart';

abstract final class UploadResultMapper {
  static UploadResult toEntity({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required UploadAndCreateFileResponseDto dto,
  }) {
    return UploadResult(
      taskId: taskId,
      purpose: purpose,
      scope: scope,
      file: UploadedFile(
        fileId: dto.fileId,
        url: dto.url,
        name: dto.name,
        size: dto.size,
        mimeType: dto.mimeType,
        md5: dto.md5,
        thumbFileId: dto.thumbFileId,
      ),
    );
  }
}
