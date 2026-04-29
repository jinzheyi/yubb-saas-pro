# IM Flutter 文件预览代码模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：文件预览相关控制器、协调器、provider、page 的建议代码骨架模板  

---

## 1. 目标

让文件预览专项从设计文档直接进入可生成 Dart 骨架代码的阶段。

---

## 2. `file_preview_page.dart` 模板

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilePreviewPage extends ConsumerStatefulWidget {
  const FilePreviewPage({
    super.key,
    required this.args,
  });

  final FilePreviewArgs args;

  @override
  ConsumerState<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends ConsumerState<FilePreviewPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(filePreviewControllerProvider.notifier).initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filePreviewControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.args?.fileName ?? '文件预览'),
      ),
      body: switch (state.status) {
        FilePreviewStatus.initial ||
        FilePreviewStatus.loadingStrategy ||
        FilePreviewStatus.resolvingCapability => const AppLoadingView(),
        FilePreviewStatus.failed => AppErrorView(error: state.error),
        FilePreviewStatus.downloadOnly => DownloadOnlyView(
            descriptor: state.descriptor,
            onDownload: () =>
                ref.read(filePreviewControllerProvider.notifier).download(),
          ),
        FilePreviewStatus.rendering => FilePreviewBody(
            state: state,
          ),
      },
    );
  }
}
```

---

## 3. `file_preview_controller.dart` 模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilePreviewController extends StateNotifier<FilePreviewState> {
  FilePreviewController(
    this._fileRepository,
    this._fileOpenCoordinator,
    this._platformCapabilities,
    this._externalOpenerService,
    this._downloadService,
  ) : super(const FilePreviewState());

  final FileRepository _fileRepository;
  final FileOpenCoordinator _fileOpenCoordinator;
  final PlatformCapabilities _platformCapabilities;
  final ExternalOpenerService _externalOpenerService;
  final DownloadService _downloadService;

  Future<void> initialize(FilePreviewArgs args) async {
    state = state.copyWith(
      args: args,
      status: FilePreviewStatus.loadingStrategy,
      error: null,
      pendingAction: FilePreviewAction.none,
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

  Future<void> retry() async {
    final args = state.args;
    if (args == null) return;
    await initialize(args);
  }

  Future<void> download() async {
    final descriptor = state.descriptor;
    if (descriptor == null || descriptor.downloadUrl == null) return;

    state = state.copyWith(
      pendingAction: FilePreviewAction.downloading,
    );

    try {
      await _downloadService.download(Uri.parse(descriptor.downloadUrl!));
    } finally {
      state = state.copyWith(
        pendingAction: FilePreviewAction.none,
      );
    }
  }

  Future<void> openExternal() async {
    final plan = state.openPlan;
    if (plan == null || plan.resolvedUrl == null) return;

    state = state.copyWith(
      pendingAction: FilePreviewAction.openingExternal,
    );

    try {
      await _externalOpenerService.open(Uri.parse(plan.resolvedUrl!));
    } finally {
      state = state.copyWith(
        pendingAction: FilePreviewAction.none,
      );
    }
  }
}
```

---

## 4. `file_open_coordinator.dart` 模板

```dart
class FileOpenCoordinator {
  const FileOpenCoordinator();

  ResolvedFileOpenPlan resolve({
    required FilePreviewDescriptor descriptor,
    required PlatformCapabilities platformCapabilities,
  }) {
    switch (descriptor.renderStrategy) {
      case FileRenderStrategy.nativePdf:
      case FileRenderStrategy.nativeImage:
      case FileRenderStrategy.nativeVideo:
      case FileRenderStrategy.nativeAudio:
      case FileRenderStrategy.nativeText:
      case FileRenderStrategy.nativeMarkdown:
      case FileRenderStrategy.serverConvertedPdf:
      case FileRenderStrategy.serverConvertedHtml:
        return ResolvedFileOpenPlan.inPage(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl: descriptor.previewUrl ?? descriptor.convertedPdfUrl,
        );
      case FileRenderStrategy.embeddedOfficeViewer:
        return ResolvedFileOpenPlan.embedded(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl: descriptor.viewerUrl,
        );
      case FileRenderStrategy.downloadOnly:
        return ResolvedFileOpenPlan.downloadOnly(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl: descriptor.downloadUrl,
          fallbackMessage: descriptor.message,
        );
    }
  }
}
```

---

## 5. `file_preview_providers.dart` 模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileOpenCoordinatorProvider = Provider<FileOpenCoordinator>((ref) {
  return const FileOpenCoordinator();
});

final filePreviewControllerProvider =
    StateNotifierProvider<FilePreviewController, FilePreviewState>((ref) {
  return FilePreviewController(
    ref.watch(fileRepositoryProvider),
    ref.watch(fileOpenCoordinatorProvider),
    ref.watch(platformCapabilitiesProvider),
    ref.watch(externalOpenerServiceProvider),
    ref.watch(downloadServiceProvider),
  );
});
```

---

## 6. `file_preview_body.dart` 模板

```dart
class FilePreviewBody extends StatelessWidget {
  const FilePreviewBody({
    super.key,
    required this.state,
  });

  final FilePreviewState state;

  @override
  Widget build(BuildContext context) {
    final strategy = state.openPlan?.renderStrategy;

    switch (strategy) {
      case FileRenderStrategy.nativePdf:
      case FileRenderStrategy.serverConvertedPdf:
        return PdfPreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.nativeImage:
        return ImagePreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.nativeVideo:
        return VideoPreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.nativeAudio:
        return AudioPreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.nativeText:
      case FileRenderStrategy.nativeMarkdown:
        return TextPreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.serverConvertedHtml:
        return HtmlPreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.embeddedOfficeViewer:
        return EmbeddedOfficePreviewBody(url: state.openPlan?.resolvedUrl);
      case FileRenderStrategy.downloadOnly:
      case null:
        return const SizedBox.shrink();
    }
  }
}
```

---

## 7. `download_only_view.dart` 模板

```dart
class DownloadOnlyView extends StatelessWidget {
  const DownloadOnlyView({
    super.key,
    required this.descriptor,
    required this.onDownload,
  });

  final FilePreviewDescriptor? descriptor;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(descriptor?.message ?? '当前文件不支持在线预览'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onDownload,
            child: const Text('下载文件'),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. 原则

1. 页面只负责渲染与动作分发。
2. 打开策略决定权在 controller + coordinator，不在 Widget。
3. 所有 URL 都通过 descriptor / plan 传递，不在页面拼接。
4. Office 首期主路径优先 `serverConvertedPdf/serverConvertedHtml`，`embeddedOfficeViewer` 只保留扩展位。
