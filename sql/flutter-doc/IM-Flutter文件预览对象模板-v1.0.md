# IM Flutter 文件预览对象模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：文件预览相关 DTO、Entity、Plan、State 的示例代码模板  

---

## 1. `FilePreviewArgs` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_preview_args.freezed.dart';

@freezed
class FilePreviewArgs with _$FilePreviewArgs {
  const factory FilePreviewArgs({
    required String fileId,
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? messageId,
    String? chatId,
    String? sourceType,
  }) = _FilePreviewArgs;
}
```

---

## 2. `FileRenderStrategy` 模板

```dart
enum FileRenderStrategy {
  nativePdf,
  nativeImage,
  nativeVideo,
  nativeAudio,
  nativeText,
  nativeMarkdown,
  serverConvertedPdf,
  serverConvertedHtml,
  embeddedOfficeViewer,
  downloadOnly,
}
```

---

## 3. `FilePreviewDescriptor` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_preview_descriptor.freezed.dart';

@freezed
class FilePreviewDescriptor with _$FilePreviewDescriptor {
  const factory FilePreviewDescriptor({
    required String fileId,
    required String fileName,
    required String mimeType,
    required String extension,
    required int fileSize,
    required FileRenderStrategy renderStrategy,
    String? previewUrl,
    String? downloadUrl,
    String? viewerUrl,
    String? convertedPdfUrl,
    int? expiresAt,
    @Default(false) bool unstable,
    String? message,
  }) = _FilePreviewDescriptor;
}
```

说明：

- `embedded()` 工厂仅作为保留扩展位
- 首期主方案优先 `inPage(serverConvertedPdf/serverConvertedHtml)`

---

## 4. `ResolvedFileOpenPlan` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'resolved_file_open_plan.freezed.dart';

@freezed
class ResolvedFileOpenPlan with _$ResolvedFileOpenPlan {
  const factory ResolvedFileOpenPlan({
    required FileRenderStrategy renderStrategy,
    required bool shouldOpenInPage,
    required bool shouldUseEmbeddedViewer,
    required bool shouldOpenExternal,
    required bool shouldDownloadOnly,
    String? resolvedUrl,
    String? fallbackMessage,
  }) = _ResolvedFileOpenPlan;

  const ResolvedFileOpenPlan._();

  factory ResolvedFileOpenPlan.inPage({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: true,
      shouldUseEmbeddedViewer: false,
      shouldOpenExternal: false,
      shouldDownloadOnly: false,
      resolvedUrl: resolvedUrl,
    );
  }

  factory ResolvedFileOpenPlan.embedded({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: true,
      shouldUseEmbeddedViewer: true,
      shouldOpenExternal: false,
      shouldDownloadOnly: false,
      resolvedUrl: resolvedUrl,
    );
  }

  factory ResolvedFileOpenPlan.downloadOnly({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
    String? fallbackMessage,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: false,
      shouldUseEmbeddedViewer: false,
      shouldOpenExternal: false,
      shouldDownloadOnly: true,
      resolvedUrl: resolvedUrl,
      fallbackMessage: fallbackMessage,
    );
  }
}
```

---

## 5. `FileOpenStrategyResponseDto` 模板

```dart
import 'package:json_annotation/json_annotation.dart';

part 'file_open_strategy_response_dto.g.dart';

@JsonSerializable()
class FileOpenStrategyResponseDto {
  const FileOpenStrategyResponseDto({
    required this.renderStrategy,
    required this.contentType,
    this.previewUrl,
    this.downloadUrl,
    this.viewerUrl,
    this.convertedPdfUrl,
    this.expiresAt,
    this.unstable = false,
    this.message,
  });

  final String renderStrategy;
  final String contentType;
  final String? previewUrl;
  final String? downloadUrl;
  final String? viewerUrl;
  final String? convertedPdfUrl;
  final int? expiresAt;
  final bool unstable;
  final String? message;

  factory FileOpenStrategyResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FileOpenStrategyResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FileOpenStrategyResponseDtoToJson(this);
}
```

---

## 6. `FilePreviewState` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_preview_state.freezed.dart';

@freezed
class FilePreviewState with _$FilePreviewState {
  const factory FilePreviewState({
    FilePreviewArgs? args,
    @Default(FilePreviewStatus.initial) FilePreviewStatus status,
    FilePreviewDescriptor? descriptor,
    ResolvedFileOpenPlan? openPlan,
    FileCapability? capability,
    @Default(FilePreviewAction.none) FilePreviewAction pendingAction,
    AppError? error,
  }) = _FilePreviewState;
}
```

---

## 7. `FileOpenStrategyResponseDtoMapper` 模板

```dart
class FileOpenStrategyResponseDtoMapper {
  const FileOpenStrategyResponseDtoMapper._();

  static FilePreviewDescriptor toEntity({
    required FilePreviewArgs args,
    required FileOpenStrategyResponseDto dto,
  }) {
    return FilePreviewDescriptor(
      fileId: args.fileId,
      fileName: args.fileName,
      mimeType: args.mimeType,
      extension: _resolveExtension(args.fileName),
      fileSize: args.fileSize,
      renderStrategy: _mapStrategy(dto.renderStrategy),
      previewUrl: dto.previewUrl,
      downloadUrl: dto.downloadUrl,
      viewerUrl: dto.viewerUrl,
      convertedPdfUrl: dto.convertedPdfUrl,
      expiresAt: dto.expiresAt,
      unstable: dto.unstable,
      message: dto.message,
    );
  }
}
```
