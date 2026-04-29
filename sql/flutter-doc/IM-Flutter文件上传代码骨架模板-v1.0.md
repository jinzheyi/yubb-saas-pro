# IM Flutter 文件上传代码骨架模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：上传协调器、repository、provider、controller 的建议代码骨架模板  

---

## 1. `file_repository.dart` 模板

```dart
abstract class FileRepository {
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
  });

  Future<FilePreviewDescriptor> getFileOpenStrategy({
    required String fileId,
    int expirationSeconds = 600,
  });

  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = 600,
  });
}
```

---

## 2. `file_http_data_source.dart` 模板

```dart
class FileHttpDataSource {
  FileHttpDataSource(this._dio);

  final Dio _dio;

  Future<UploadAndCreateFileResponseDto> uploadAndCreateFile({
    required UploadRequestDto request,
  }) async {
    final formData = FormData.fromMap({
      'directory': request.directory,
      'file': await MultipartFile.fromFile(
        request.localUri,
        filename: request.fileName,
        contentType: DioMediaType.parse(request.mimeType),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/infra/file/upload-and-return-id',
      data: formData,
    );

    return UploadAndCreateFileResponseDto.fromJson(response.data!);
  }
}
```

---

## 3. `file_repository_impl.dart` 模板

```dart
class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl(
    this._httpDataSource,
    this._fileCapabilityMapper,
  );

  final FileHttpDataSource _httpDataSource;
  final FileCapabilityMapper _fileCapabilityMapper;

  @override
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
  }) async {
    final directory = UploadDirectoryResolver.resolve(
      purpose: purpose,
      scope: scope,
    );

    final dto = await _httpDataSource.uploadAndCreateFile(
      request: UploadRequestDto(
        localUri: localUri,
        fileName: displayName,
        directory: directory.value,
        fieldName: 'file',
        mimeType: mimeType,
      ),
    );

    return UploadResultMapper.toEntity(
      taskId: taskId,
      purpose: purpose,
      scope: scope,
      dto: dto,
    );
  }

  @override
  Future<FilePreviewDescriptor> getFileOpenStrategy({
    required String fileId,
    int expirationSeconds = 600,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = 600,
  }) {
    throw UnimplementedError();
  }
}
```

---

## 4. `upload_chat_asset_use_case.dart` 模板

```dart
class UploadChatAssetUseCase {
  UploadChatAssetUseCase(this._fileRepository);

  final FileRepository _fileRepository;

  Future<UploadResult> execute({
    required String taskId,
    required ChatUploadInput input,
  }) {
    return _fileRepository.uploadAndCreateFile(
      taskId: taskId,
      purpose: input.purpose,
      scope: input.scope,
      localUri: input.localUri,
      displayName: input.displayName,
      mimeType: input.mimeType,
    );
  }
}
```

---

## 5. `send_uploaded_message_use_case.dart` 模板

```dart
class SendUploadedMessageUseCase {
  SendUploadedMessageUseCase(this._messageRepository);

  final MessageRepository _messageRepository;

  Future<void> sendImage({
    required UploadResult upload,
    required int width,
    required int height,
  }) {
    return _messageRepository.sendImage(
      chatId: _resolveChatId(upload.scope),
      fileId: upload.file.fileId,
      url: upload.file.url,
      thumbnailUrl: upload.file.url,
      width: width,
      height: height,
      size: upload.file.size,
    );
  }

  Future<void> sendFile({
    required UploadResult upload,
  }) {
    return _messageRepository.sendFile(
      chatId: _resolveChatId(upload.scope),
      fileId: upload.file.fileId,
      url: upload.file.url,
      fileName: upload.file.name,
      size: upload.file.size,
      fileType: upload.file.mimeType,
    );
  }

  String _resolveChatId(UploadScope scope) {
    return scope.map(
      directChat: (s) => s.chatId,
      groupChat: (s) => s.chatId,
      profile: (_) => '',
      sticker: (_) => '',
    );
  }
}
```

---

## 6. `chat_upload_coordinator.dart` 模板

```dart
class ChatUploadCoordinator {
  ChatUploadCoordinator(
    this._uploadChatAssetUseCase,
    this._sendUploadedMessageUseCase,
    this._taskIdFactory,
  );

  final UploadChatAssetUseCase _uploadChatAssetUseCase;
  final SendUploadedMessageUseCase _sendUploadedMessageUseCase;
  final TaskIdFactory _taskIdFactory;

  Future<UploadTask> uploadImage({
    required ChatUploadInput input,
    required void Function(UploadTask task) onTaskChanged,
  }) async {
    final task = UploadTask(
      taskId: _taskIdFactory.create(),
      purpose: input.purpose,
      scope: input.scope,
      localUri: input.localUri,
      displayName: input.displayName,
      mimeType: input.mimeType,
      fileSize: input.fileSize,
      createdAt: DateTime.now(),
    );

    onTaskChanged(task.copyWith(status: UploadTaskStatus.preparing));

    final uploaded = await _uploadChatAssetUseCase.execute(
      taskId: task.taskId,
      input: input,
    );

    onTaskChanged(
      task.copyWith(
        status: UploadTaskStatus.uploaded,
        progress: 100,
        uploadedFileId: uploaded.file.fileId,
        uploadedUrl: uploaded.file.url,
        checksum: uploaded.file.md5,
      ),
    );

    onTaskChanged(task.copyWith(status: UploadTaskStatus.sending));

    await _sendUploadedMessageUseCase.sendImage(
      upload: uploaded,
      width: 0,
      height: 0,
    );

    final sentTask = task.copyWith(
      status: UploadTaskStatus.sent,
      progress: 100,
      uploadedFileId: uploaded.file.fileId,
      uploadedUrl: uploaded.file.url,
      checksum: uploaded.file.md5,
    );
    onTaskChanged(sentTask);
    return sentTask;
  }
}
```

---

## 7. `chat_media_controller.dart` 上传片段模板

```dart
class ChatMediaController extends StateNotifier<ChatUploadState> {
  ChatMediaController(
    this._chatUploadCoordinator,
    this._mediaPickerFacade,
  ) : super(const ChatUploadState());

  final ChatUploadCoordinator _chatUploadCoordinator;
  final MediaPickerFacade _mediaPickerFacade;

  Future<void> pickAndUploadImage({
    required UploadScope scope,
  }) async {
    final file = await _mediaPickerFacade.pickSingleImage();
    if (file == null) return;

    final input = ChatUploadInput(
      purpose: UploadPurpose.chatImage,
      scope: scope,
      localUri: file.localUri,
      displayName: file.displayName,
      mimeType: file.mimeType,
      fileSize: file.fileSize,
    );

    await _chatUploadCoordinator.uploadImage(
      input: input,
      onTaskChanged: _upsertTask,
    );
  }

  void _upsertTask(UploadTask task) {
    final tasks = [...state.tasks];
    final index = tasks.indexWhere((it) => it.taskId == task.taskId);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    state = state.copyWith(
      tasks: tasks,
      activeTaskId: task.taskId,
      busy: task.status == UploadTaskStatus.preparing ||
          task.status == UploadTaskStatus.uploading ||
          task.status == UploadTaskStatus.sending,
    );
  }
}
```

---

## 8. provider 模板

```dart
final uploadChatAssetUseCaseProvider = Provider<UploadChatAssetUseCase>((ref) {
  return UploadChatAssetUseCase(ref.watch(fileRepositoryProvider));
});

final sendUploadedMessageUseCaseProvider =
    Provider<SendUploadedMessageUseCase>((ref) {
  return SendUploadedMessageUseCase(ref.watch(messageRepositoryProvider));
});

final chatUploadCoordinatorProvider = Provider<ChatUploadCoordinator>((ref) {
  return ChatUploadCoordinator(
    ref.watch(uploadChatAssetUseCaseProvider),
    ref.watch(sendUploadedMessageUseCaseProvider),
    ref.watch(taskIdFactoryProvider),
  );
});
```

---

## 9. 失败与重试骨架

```dart
extension ChatUploadStateX on ChatUploadState {
  UploadTask? findTask(String taskId) {
    for (final task in tasks) {
      if (task.taskId == taskId) return task;
    }
    return null;
  }
}

class RetryUploadedMessageUseCase {
  RetryUploadedMessageUseCase(this._sendUploadedMessageUseCase);

  final SendUploadedMessageUseCase _sendUploadedMessageUseCase;

  Future<void> retry({
    required UploadTask task,
  }) async {
    if (task.uploadedFileId == null || task.uploadedUrl == null) {
      throw StateError('task has no uploaded file');
    }
    // 这里按 task.purpose 分流，不重新上传，只重发消息
  }
}
```

---

## 10. 原则

1. 上传与发送必须拆成两个 use case
2. 页面只触发 pick/upload/send 动作，不直接调用 `Dio` 或 `FormData`
3. 失败重试优先重发消息，不重复上传
4. `dict/nav-state/avatar` 这类基础能力不需要单独拆成多份上传依赖模板，合并成 `core` 基础能力模板更合适
