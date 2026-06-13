import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';

class UploadChatAssetUseCase {
  const UploadChatAssetUseCase(this._fileRepository);

  final FileRepository _fileRepository;

  Future<UploadResult> execute({
    required String taskId,
    required ChatUploadInput input,
    void Function(int sent, int total)? onProgress,
  }) {
    return _fileRepository.uploadAndCreateFile(
      taskId: taskId,
      purpose: input.purpose,
      scope: input.scope,
      localUri: input.localUri,
      displayName: input.displayName,
      mimeType: input.mimeType,
      bytes: input.bytes,
      onProgress: onProgress,
    );
  }
}
