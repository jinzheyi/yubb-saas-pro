import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_upload_execution_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/multipart_upload_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/presigned_url_upload_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_uploaded_message_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/upload_chat_asset_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_upload_input.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_task_status.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/uploaded_file.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/services/upload_directory_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/upload_progress_tracker.dart';

class ChatUploadCoordinator {
  ChatUploadCoordinator(
    this._uploadChatAssetUseCase,
    this._sendUploadedMessageUseCase,
    this._uuid, {
    UploadProgressTracker? progressTracker,
    MultipartUploadUseCase? multipartUploadUseCase,
    PresignedUrlUploadUseCase? presignedUrlUploadUseCase,
  }) : _progressTracker = progressTracker,
       _multipartUploadUseCase = multipartUploadUseCase,
       _presignedUrlUploadUseCase = presignedUrlUploadUseCase;

  final UploadChatAssetUseCase _uploadChatAssetUseCase;
  final SendUploadedMessageUseCase _sendUploadedMessageUseCase;
  final MultipartUploadUseCase? _multipartUploadUseCase;
  final PresignedUrlUploadUseCase? _presignedUrlUploadUseCase;
  final Uuid _uuid;
  final UploadProgressTracker? _progressTracker;

  /// 断线重试最大次数（不含首次）
  static const int _maxRetries = 3;

  /// 分片上传阈值（10MB）
  static const int _multipartThreshold = 10 * 1024 * 1024;

  /// 需要重试的异常类型（网络异常、超时等）
  static const _retryableExceptions = {
    'SocketException',
    'TimeoutException',
    'ConnectionError',
    'HttpException',
    'DioException',
  };

  Future<ChatUploadExecutionResult> uploadImage({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
    String? clientMessageId,
    int width = 0,
    int height = 0,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      clientMessageId: clientMessageId,
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
    String? clientMessageId,
    int duration = 0,
    int width = 0,
    int height = 0,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      clientMessageId: clientMessageId,
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
    String? clientMessageId,
  }) {
    return _execute(
      input: input,
      onTaskChanged: onTaskChanged,
      clientMessageId: clientMessageId,
      sendUploaded: (uploaded, taskId) async {
        return _sendUploadedMessageUseCase.sendFile(
          upload: uploaded,
          clientMessageId: taskId,
        );
      },
    );
  }

  /// 将 [UploadTaskStatus] 映射为 [UploadProgressStatus]
  static UploadProgressStatus _mapProgressStatus(UploadTaskStatus status) {
    switch (status) {
      case UploadTaskStatus.queued:
        return UploadProgressStatus.queued;
      case UploadTaskStatus.preparing:
        return UploadProgressStatus.preparing;
      case UploadTaskStatus.uploading:
        return UploadProgressStatus.uploading;
      case UploadTaskStatus.uploaded:
        return UploadProgressStatus.uploaded;
      case UploadTaskStatus.sending:
        return UploadProgressStatus.sending;
      case UploadTaskStatus.sent:
        return UploadProgressStatus.sent;
      case UploadTaskStatus.failed:
        return UploadProgressStatus.failed;
      case UploadTaskStatus.cancelled:
        return UploadProgressStatus.cancelled;
    }
  }

  Future<ChatUploadExecutionResult> _execute({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
    String? clientMessageId,
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
    _notifyProgress(task, clientMessageId);

    UploadResult? uploaded;

    // 判断是否使用分片上传
    final useMultipart =
        input.fileSize > _multipartThreshold &&
        _multipartUploadUseCase != null;

    // 上传阶段：支持断线重试
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // 重试时更新任务状态，携带重试次数
          task = task.copyWith(
            status: UploadTaskStatus.preparing,
            errorMessage: '网络异常，正在重试（$attempt/$_maxRetries）',
          );
          onTaskChanged(task);
          _notifyProgress(task, clientMessageId);

          // 指数退避：等待 1s、2s、4s
          final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
          await Future.delayed(delay);
        }

        task = task.copyWith(status: UploadTaskStatus.uploading, progress: 0);
        onTaskChanged(task);
        _notifyProgress(task, clientMessageId);

        uploaded = await _doUpload(
          task: task,
          input: input,
          useMultipart: useMultipart,
          onProgress: (percent, retryLabel) {
            task = task.copyWith(
              status: UploadTaskStatus.uploading,
              progress: percent,
              errorMessage:
                  retryLabel.isNotEmpty ? '上传中 $retryLabel' : null,
            );
            onTaskChanged(task);
            _notifyProgress(task, clientMessageId);
          },
          lastRetryAttempt: attempt,
        );
        // 上传成功，跳出重试循环
        break;
      } catch (error) {
        // 判断是否为可重试的网络异常
        final errorType = error.runtimeType.toString();
        final errorString = error.toString();
        final isRetryable = _retryableExceptions.any(
          (type) => errorType.contains(type) || errorString.contains(type),
        );

        if (isRetryable && attempt < _maxRetries) {
          // 可重试异常，继续下一轮循环
          continue;
        }

        // 不可重试异常，或已达最大重试次数
        task = task.copyWith(
          status: UploadTaskStatus.failed,
          errorMessage: error.toString(),
        );
        onTaskChanged(task);
        _notifyProgress(task, clientMessageId);
        rethrow;
      }
    }

    // 防御性检查：理论上不会走到这里，但确保安全
    if (uploaded == null) {
      task = task.copyWith(
        status: UploadTaskStatus.failed,
        errorMessage: '上传结果为空',
      );
      onTaskChanged(task);
      _notifyProgress(task, clientMessageId);
      throw StateError('upload_result_is_null');
    }

    task = task.copyWith(
      status: UploadTaskStatus.uploaded,
      progress: 100,
      uploadedFileId: uploaded.file.fileId,
      uploadedUrl: uploaded.file.url,
      checksum: uploaded.file.md5,
    );
    onTaskChanged(task);
    _notifyProgress(task, clientMessageId);

    task = task.copyWith(status: UploadTaskStatus.sending);
    onTaskChanged(task);
    _notifyProgress(task, clientMessageId);

    final sent = await sendUploaded(uploaded, task.taskId);

    task = task.copyWith(status: UploadTaskStatus.sent);
    onTaskChanged(task);
    _notifyProgress(task, clientMessageId);

    // 上传完成后清理进度记录
    _removeProgress(task.taskId, clientMessageId);

    return ChatUploadExecutionResult(task: task, message: sent.message);
  }

  /// 执行实际上传（根据配置选择预签名直传、分片上传或普通上传）
  ///
  /// 上传策略优先级：
  /// 1. 预签名 URL 直传（S3/MinIO）：当 [_presignedUrlUploadUseCase] 不为空时使用
  /// 2. 分片上传（本地存储）：当文件大于阈值且 [_multipartUploadUseCase] 不为空时使用
  /// 3. 普通上传：默认方式
  Future<UploadResult> _doUpload({
    required UploadTask task,
    required ChatUploadInput input,
    required bool useMultipart,
    required void Function(int progress, String retryLabel) onProgress,
    required int lastRetryAttempt,
  }) async {
    final retryLabel =
        lastRetryAttempt > 0 ? '（重试$lastRetryAttempt次）' : '';

    // 优先使用预签名 URL 直传（S3/MinIO 支持）
    if (_presignedUrlUploadUseCase != null) {
      return _doPresignedUpload(
        task: task,
        input: input,
        onProgress: (progress) =>
            onProgress((progress * 100).toInt(), retryLabel),
      );
    }

    // 其次使用分片上传（本地存储支持）
    if (useMultipart) {
      return _doMultipartUpload(
        task: task,
        input: input,
        onProgress: (progress) =>
            onProgress((progress * 100).toInt(), retryLabel),
      );
    }

    // 最后使用普通上传
    return _uploadChatAssetUseCase.execute(
      taskId: task.taskId,
      input: input,
      onProgress: (sent, total) {
        // 将 Dio 的字节进度转为百分比（0~100）
        final percent = total > 0 ? ((sent * 100) ~/ total) : 0;
        onProgress(percent, retryLabel);
      },
    );
  }

  /// 执行预签名 URL 直传（S3/MinIO）
  ///
  /// 客户端先向后端请求预签名上传 URL，然后直接上传到 S3/MinIO，
  /// 最后调用后端接口创建文件记录。
  ///
  /// 如果后端不支持预签名 URL（抛出 [PresignedUrlNotSupportedException]），
  /// 则降级到普通上传方式。
  Future<UploadResult> _doPresignedUpload({
    required UploadTask task,
    required ChatUploadInput input,
    required void Function(double progress) onProgress,
  }) async {
    final directory = UploadDirectoryResolver.resolve(
      purpose: input.purpose,
      scope: input.scope,
    ).value;

    final file = File(input.localUri);

    try {
      final result = await _presignedUrlUploadUseCase!.execute(
        file: file,
        directory: directory,
        fileName: input.displayName,
        mimeType: input.mimeType,
        onProgress: onProgress,
      );

      // 将预签名上传结果包装为 UploadResult，以与普通上传保持一致
      return UploadResult(
        taskId: task.taskId,
        purpose: input.purpose,
        scope: input.scope,
        file: UploadedFile(
          fileId: result.fileId.toString(),
          url: result.url,
          name: input.displayName,
          size: input.fileSize,
          mimeType: input.mimeType,
        ),
      );
    } on PresignedUrlNotSupportedException {
      // 后端不支持预签名 URL，降级到普通上传
      return _uploadChatAssetUseCase.execute(
        taskId: task.taskId,
        input: input,
        onProgress: (sent, total) {
          final percent = total > 0 ? ((sent * 100) ~/ total) : 0;
          onProgress(percent / 100);
        },
      );
    }
  }

  /// 执行分片上传
  Future<UploadResult> _doMultipartUpload({
    required UploadTask task,
    required ChatUploadInput input,
    required void Function(double progress) onProgress,
  }) async {
    final directory = UploadDirectoryResolver.resolve(
      purpose: input.purpose,
      scope: input.scope,
    ).value;

    final file = File(input.localUri);
    final mergeResult = await _multipartUploadUseCase!.execute(
      file: file,
      directory: directory,
      onProgress: onProgress,
    );

    // 将分片上传结果包装为 UploadResult，以与普通上传保持一致
    return UploadResult(
      taskId: task.taskId,
      purpose: input.purpose,
      scope: input.scope,
      file: UploadedFile(
        fileId: mergeResult.fileId.toString(),
        url: mergeResult.url,
        name: input.displayName,
        size: input.fileSize,
        mimeType: input.mimeType,
      ),
    );
  }

  /// 通知进度追踪器
  void _notifyProgress(UploadTask task, String? clientMessageId) {
    final trackerKey = clientMessageId?.trim().isNotEmpty == true
        ? clientMessageId!
        : task.taskId;
    _progressTracker?.updateProgress(
      taskId: trackerKey,
      progress: task.progress,
      status: _mapProgressStatus(task.status),
      errorMessage: task.errorMessage,
    );
  }

  /// 移除进度追踪记录
  void _removeProgress(String taskId, String? clientMessageId) {
    final trackerKey = clientMessageId?.trim().isNotEmpty == true
        ? clientMessageId!
        : taskId;
    _progressTracker?.remove(trackerKey);
  }
}
