# IM Flutter 文件预览控制器与策略设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：文件预览策略枚举、领域对象、控制器状态机、协调器与代码骨架设计  

---

## 1. 目标

把文件预览从“方案说明”进一步收口成可直接编码的控制器与对象设计。

---

## 2. 核心领域对象

### 2.1 `FilePreviewArgs`

职责：

- 页面路由参数

字段：

- `fileId`
- `fileName`
- `mimeType`
- `fileSize`
- `messageId`
- `chatId`
- `sourceType`

### 2.2 `FilePreviewDescriptor`

职责：

- 文件预览统一描述对象

字段：

- `fileId`
- `fileName`
- `mimeType`
- `extension`
- `fileSize`
- `renderStrategy`
- `previewUrl`
- `downloadUrl`
- `viewerUrl`
- `convertedPdfUrl`
- `expiresAt`
- `unstable`
- `message`

### 2.3 `FileCapability`

职责：

- 表示当前平台对文件渲染能力的判断结果

字段：

- `canNativeRender`
- `canSearchText`
- `canPaginate`
- `canShare`
- `canDownload`
- `canOpenExternal`

---

## 3. 策略枚举设计

### 3.1 `FileRenderStrategy`

建议定义：

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

### 3.2 `FilePreviewStatus`

建议定义：

```dart
enum FilePreviewStatus {
  initial,
  loadingStrategy,
  resolvingCapability,
  rendering,
  downloadOnly,
  failed,
}
```

### 3.3 `FilePreviewAction`

建议定义：

```dart
enum FilePreviewAction {
  none,
  downloading,
  openingExternal,
  retrying,
  sharing,
}
```

---

## 4. DTO 设计

### 4.1 `FileOpenStrategyResponseDto`

字段：

- `renderStrategy`
- `contentType`
- `previewUrl`
- `downloadUrl`
- `viewerUrl`
- `convertedPdfUrl`
- `expiresAt`
- `unstable`
- `message`

### 4.2 `FilePreviewDescriptorMapper`

职责：

- `FileOpenStrategyResponseDto -> FilePreviewDescriptor`
- 统一 extension / mimeType / strategy 规范化

---

## 5. Repository 契约

### 5.1 `FileRepository`

建议方法：

- `Future<FilePreviewDescriptor> getFilePreviewDescriptor(FilePreviewArgs args)`
- `Future<Uri> getDownloadUri(String fileId)`
- `Future<Uri> getConvertedPdfUri(String fileId)`

---

## 6. `FileOpenCoordinator` 设计

### 6.1 职责

- 根据文件类型与服务端返回策略决定最终打开方式
- 屏蔽页面对平台差异的感知

### 6.2 输入

- `FilePreviewArgs`
- `FilePreviewDescriptor`
- `PlatformCapabilities`

### 6.3 输出

- `ResolvedFileOpenPlan`

### 6.4 `ResolvedFileOpenPlan`

字段：

- `renderStrategy`
- `shouldOpenInPage`
- `shouldUseEmbeddedViewer`
- `shouldOpenExternal`
- `shouldDownloadOnly`
- `resolvedUrl`
- `fallbackMessage`

规则：

- `shouldUseEmbeddedViewer` 只作为保留扩展位
- 首期主链路不允许 controller 主动偏向嵌入 viewer

---

## 7. `FilePreviewController` 设计

### 7.1 职责

- 加载文件打开策略
- 决定当前页面渲染方式
- 处理下载、重试、外部打开、分享

### 7.2 依赖

- `FileRepository`
- `FileOpenCoordinator`
- `PlatformCapabilities`
- `ExternalOpenerService`
- `DownloadService`

### 7.3 公开动作

- `initialize(FilePreviewArgs args)`
- `retry()`
- `download()`
- `openExternal()`
- `share()`

---

## 8. `FilePreviewState` 设计

字段：

- `args`
- `status`
- `descriptor`
- `openPlan`
- `capability`
- `pendingAction`
- `error`

### 8.1 代码模板

```dart
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

## 9. `FilePreviewController` 状态机

### 9.1 初始化流程

| 事件 | 动作 | 状态变化 |
|---|---|---|
| 进入页面 | `initialize(args)` | `initial -> loadingStrategy` |
| 服务端策略返回 | `resolveCapability()` | `loadingStrategy -> resolvingCapability` |
| 打开方案解析完成 | `setOpenPlan()` | `resolvingCapability -> rendering` |
| 策略不可预览 | `setDownloadOnly()` | `resolvingCapability -> downloadOnly` |
| 初始化失败 | `setError()` | `loadingStrategy/resolvingCapability -> failed` |

### 9.2 动作流程

| 事件 | 动作 | 状态变化 |
|---|---|---|
| 点击下载 | `download()` | `rendering -> pendingAction.downloading -> rendering` |
| 点击外部打开 | `openExternal()` | `rendering -> pendingAction.openingExternal -> rendering` |
| 点击重试 | `retry()` | `failed -> loadingStrategy` |

---

## 10. `FilePreviewController` 代码骨架

```dart
class FilePreviewController extends StateNotifier<FilePreviewState> {
  FilePreviewController(
    this._fileRepository,
    this._fileOpenCoordinator,
    this._platformCapabilities,
  ) : super(const FilePreviewState());

  final FileRepository _fileRepository;
  final FileOpenCoordinator _fileOpenCoordinator;
  final PlatformCapabilities _platformCapabilities;

  Future<void> initialize(FilePreviewArgs args) async {
    state = state.copyWith(
      args: args,
      status: FilePreviewStatus.loadingStrategy,
      error: null,
    );

    try {
      final descriptor = await _fileRepository.getFilePreviewDescriptor(args);
      state = state.copyWith(
        descriptor: descriptor,
        status: FilePreviewStatus.resolvingCapability,
      );

      final plan = _fileOpenCoordinator.resolve(
        descriptor: descriptor,
        platformCapabilities: _platformCapabilities,
      );

      state = state.copyWith(
        capability: _platformCapabilities.toFileCapability(descriptor),
        openPlan: plan,
        status: plan.shouldDownloadOnly
            ? FilePreviewStatus.downloadOnly
            : FilePreviewStatus.rendering,
      );
    } catch (e, st) {
      state = state.copyWith(
        status: FilePreviewStatus.failed,
        error: AppErrorMapper.map(e, st),
      );
    }
  }
}
```

---

## 11. 平台能力判定规则

### 11.1 Mobile

- PDF：强支持
- 图片/视频/音频：强支持
- Office：优先转换 PDF

### 11.2 Web

- PDF：强支持
- Office：优先转换结果渲染，viewer 只作可选扩展
- 文本：直接渲染

### 11.3 Desktop

- PDF：强支持
- Office：优先转 PDF，viewer 只作可选扩展
- 下载与外部打开更友好

---

## 12. 失败降级规则

1. 如果 `serverConvertedPdf` 不可用，优先降级到 `serverConvertedHtml`
2. 如果明确启用了 `embeddedOfficeViewer` 且转换不可用，可再尝试 viewer
3. 如果仍不可用，降级到 `downloadOnly`
4. 页面必须展示明确的失败说明和动作按钮
