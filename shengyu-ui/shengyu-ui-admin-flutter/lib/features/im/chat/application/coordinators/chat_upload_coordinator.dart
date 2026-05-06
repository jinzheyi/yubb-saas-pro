import 'package:uuid/uuid.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_upload_execution_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_uploaded_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/upload_chat_asset_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task_status.dart';

class ChatUploadCoordinator {
  ChatUploadCoordinator(
    this._uploadChatAssetUseCase,
    this._sendUploadedMessageUseCase,
    this._uuid,
  );

  final UploadChatAssetUseCase _uploadChatAssetUseCase;
  final SendUploadedMessageUseCase _sendUploadedMessageUseCase;
  final Uuid _uuid;

  Future<ChatUploadExecutionResult> uploadImage({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
    int width = 0,
    int height = 0,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      sendUploaded: (uploaded, taskId) async {
        return _sendUploadedMessageUseCase.sendImage(
          upload: uploaded,
          clientMessageId: taskId,
          width: width,
          height: height,
        );
      },
    );
  }

  Future<ChatUploadExecutionResult> uploadVideo({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
    int duration = 0,
    int width = 0,
    int height = 0,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      sendUploaded: (uploaded, taskId) async {
        return _sendUploadedMessageUseCase.sendVideo(
          upload: uploaded,
          clientMessageId: taskId,
          duration: duration,
          width: width,
          height: height,
        );
      },
    );
  }

  Future<ChatUploadExecutionResult> uploadFile({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      sendUploaded: (uploaded, taskId) async {
        return _sendUploadedMessageUseCase.sendFile(
          upload: uploaded,
          clientMessageId: taskId,
        );
      },
    );
  }

  Future<ChatUploadExecutionResult> _execute({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
    required Future<SendMessageResult> Function(
      UploadResult uploaded,
      String taskId,
    )
    sendUploaded,
  }) async {
    var task = UploadTask(
      taskId: _uuid.v4(),
      purpose: input.purpose,
      scope: input.scope,
      localUri: input.localUri,
      displayName: input.displayName,
      mimeType: input.mimeType,
      fileSize: input.fileSize,
      createdAt: DateTime.now(),
    );
    onTaskChanged(task);

    try {
      task = task.copyWith(status: UploadTaskStatus.preparing);
      onTaskChanged(task);

      task = task.copyWith(status: UploadTaskStatus.uploading, progress: 0);
      onTaskChanged(task);

      final uploaded = await _uploadChatAssetUseCase.execute(
        taskId: task.taskId,
        input: input,
      );

      task = task.copyWith(
        status: UploadTaskStatus.uploaded,
        progress: 100,
        uploadedFileId: uploaded.file.fileId,
        uploadedUrl: uploaded.file.url,
        checksum: uploaded.file.md5,
      );
      onTaskChanged(task);

      task = task.copyWith(status: UploadTaskStatus.sending);
      onTaskChanged(task);

      final sent = await sendUploaded(uploaded, task.taskId);

      task = task.copyWith(status: UploadTaskStatus.sent);
      onTaskChanged(task);
      return ChatUploadExecutionResult(task: task, message: sent.message);
    } catch (error) {
      task = task.copyWith(
        status: UploadTaskStatus.failed,
        errorMessage: error.toString(),
      );
      onTaskChanged(task);
      rethrow;
    }
  }
}
