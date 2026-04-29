# IM Flutter 文件上传对象模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：上传链路相关的 Entity、DTO、State、Command 示例代码模板  

---

## 1. `UploadPurpose` 模板

```dart
enum UploadPurpose {
  chatImage,
  chatVideo,
  chatFile,
  chatVoice,
  avatar,
  stickerOriginal,
  stickerThumb,
}
```

---

## 2. `UploadTaskStatus` 模板

```dart
enum UploadTaskStatus {
  queued,
  preparing,
  uploading,
  uploaded,
  sending,
  sent,
  failed,
  cancelled,
}
```

---

## 3. `UploadScope` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_scope.freezed.dart';

@freezed
class UploadScope with _$UploadScope {
  const factory UploadScope.directChat({
    required String chatId,
  }) = DirectChatUploadScope;

  const factory UploadScope.groupChat({
    required String groupId,
    required String chatId,
  }) = GroupChatUploadScope;

  const factory UploadScope.profile({
    required String userId,
  }) = ProfileUploadScope;

  const factory UploadScope.sticker({
    required String userId,
  }) = StickerUploadScope;
}
```

---

## 4. `UploadDirectory` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_directory.freezed.dart';

@freezed
class UploadDirectory with _$UploadDirectory {
  const factory UploadDirectory({
    required String value,
  }) = _UploadDirectory;
}
```

---

## 5. `ChatUploadInput` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_upload_input.freezed.dart';

@freezed
class ChatUploadInput with _$ChatUploadInput {
  const factory ChatUploadInput({
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
    required int fileSize,
  }) = _ChatUploadInput;
}
```

---

## 6. `ChatVoiceUploadInput` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_voice_upload_input.freezed.dart';

@freezed
class ChatVoiceUploadInput with _$ChatVoiceUploadInput {
  const factory ChatVoiceUploadInput({
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
    required int fileSize,
    required int duration,
    required int durationMs,
    String? md5,
  }) = _ChatVoiceUploadInput;
}
```

---

## 7. `UploadTask` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_task.freezed.dart';

@freezed
class UploadTask with _$UploadTask {
  const factory UploadTask({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
    required int fileSize,
    @Default(UploadTaskStatus.queued) UploadTaskStatus status,
    @Default(0) int progress,
    String? uploadedFileId,
    String? uploadedUrl,
    String? checksum,
    String? errorMessage,
    required DateTime createdAt,
  }) = _UploadTask;
}
```

---

## 8. `UploadedFile` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'uploaded_file.freezed.dart';

@freezed
class UploadedFile with _$UploadedFile {
  const factory UploadedFile({
    required String fileId,
    required String url,
    required String name,
    required int size,
    required String mimeType,
    String? md5,
    String? thumbFileId,
  }) = _UploadedFile;
}
```

---

## 9. `UploadResult` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_result.freezed.dart';

@freezed
class UploadResult with _$UploadResult {
  const factory UploadResult({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required UploadedFile file,
  }) = _UploadResult;
}
```

---

## 10. `UploadAndCreateFileResponseDto` 模板

```dart
import 'package:json_annotation/json_annotation.dart';

part 'upload_and_create_file_response_dto.g.dart';

@JsonSerializable()
class UploadAndCreateFileResponseDto {
  const UploadAndCreateFileResponseDto({
    required this.fileId,
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
    this.md5,
    this.thumbFileId,
  });

  final String fileId;
  final String url;
  final String name;
  final int size;
  final String mimeType;
  final String? md5;
  final String? thumbFileId;

  factory UploadAndCreateFileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UploadAndCreateFileResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadAndCreateFileResponseDtoToJson(this);
}
```

---

## 11. `UploadRequestDto` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_request_dto.freezed.dart';

@freezed
class UploadRequestDto with _$UploadRequestDto {
  const factory UploadRequestDto({
    required String localUri,
    required String fileName,
    required String directory,
    required String fieldName,
    required String mimeType,
  }) = _UploadRequestDto;
}
```

---

## 12. `ChatUploadState` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_upload_state.freezed.dart';

@freezed
class ChatUploadState with _$ChatUploadState {
  const factory ChatUploadState({
    @Default(<UploadTask>[]) List<UploadTask> tasks,
    @Default(false) bool busy,
    String? activeTaskId,
  }) = _ChatUploadState;
}
```

---

## 13. `UploadDirectoryResolver` 模板

```dart
class UploadDirectoryResolver {
  const UploadDirectoryResolver._();

  static UploadDirectory resolve({
    required UploadPurpose purpose,
    required UploadScope scope,
  }) {
    return scope.map(
      directChat: (s) => UploadDirectory(
        value: 'im/chat/${s.chatId}/${_purposeSegment(purpose)}',
      ),
      groupChat: (s) => UploadDirectory(
        value: 'im/group/${s.groupId}/${_purposeSegment(purpose)}',
      ),
      profile: (s) => UploadDirectory(
        value: 'profile/avatar/${s.userId}',
      ),
      sticker: (s) => UploadDirectory(
        value: 'im/sticker/${s.userId}',
      ),
    );
  }

  static String _purposeSegment(UploadPurpose purpose) {
    switch (purpose) {
      case UploadPurpose.chatImage:
        return 'image';
      case UploadPurpose.chatVideo:
        return 'video';
      case UploadPurpose.chatFile:
        return 'file';
      case UploadPurpose.chatVoice:
        return 'voice';
      case UploadPurpose.avatar:
        return 'avatar';
      case UploadPurpose.stickerOriginal:
      case UploadPurpose.stickerThumb:
        return 'sticker';
    }
  }
}
```

---

## 14. `UploadResultMapper` 模板

```dart
class UploadResultMapper {
  const UploadResultMapper._();

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
```

---

## 15. 原则

1. `fileId` 一律使用 `String`
2. 上传成功后的重发链路只复用 `UploadResult`，不重新上传
3. 上传目录由 resolver 统一生成，不允许页面层拼接
4. `UploadTask` 与消息发送状态分离，但允许串联推进
