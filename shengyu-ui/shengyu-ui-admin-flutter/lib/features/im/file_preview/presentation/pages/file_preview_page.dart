import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_action.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_status.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/states/file_preview_state.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/widgets/file_preview_body.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';

class FilePreviewPage extends ConsumerStatefulWidget {
  const FilePreviewPage({super.key, required this.args});

  final FilePreviewArgs args;

  @override
  ConsumerState<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends ConsumerState<FilePreviewPage> {
  bool _previewVisible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(filePreviewControllerProvider.notifier).initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(filePreviewControllerProvider);
    final pending = state.pendingAction != FilePreviewAction.none;
    final title = (state.args?.fileName.trim().isNotEmpty ?? false)
        ? state.args!.fileName.trim()
        : strings.filePreviewTitle;
    final canForward = _canForward(state);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: canForward ? 132 : null,
        leading: canForward
            ? Row(
                children: [
                  IconButton(
                    onPressed: pending
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  TextButton(
                    onPressed: pending ? null : () => _forwardFile(context),
                    child: Text(strings.filePreviewForward),
                  ),
                ],
              )
            : null,
        title: Text(title),
        actions: [
          TextButton(
            onPressed: pending || !_canDownload(state)
                ? null
                : () => _downloadFile(context),
            child: Text(strings.filePreviewDownload),
          ),
        ],
      ),
      body: switch (state.status) {
        FilePreviewStatus.initial ||
        FilePreviewStatus.loadingStrategy ||
        FilePreviewStatus.resolvingCapability => const AppLoadingView(),
        FilePreviewStatus.failed => AppErrorView(
          error: state.error,
          onRetry: () {
            ref.read(filePreviewControllerProvider.notifier).retry();
          },
        ),
        FilePreviewStatus.downloadOnly ||
        FilePreviewStatus.rendering => _FileDetailBody(
          state: state,
          previewVisible: _previewVisible,
          onPreview: pending || !_canPreview(state)
              ? null
              : () => _previewFile(context, state),
          onDownload: pending || !_canDownload(state)
              ? null
              : () => _downloadFile(context),
        ),
      },
    );
  }

  bool _canForward(FilePreviewState state) {
    final messageId = state.args?.messageId?.trim() ?? '';
    return messageId.isNotEmpty && messageId != '0';
  }

  bool _canDownload(FilePreviewState state) {
    return state.capability?.canDownload ?? false;
  }

  bool _canPreview(FilePreviewState state) {
    if (_supportsInlinePreview(state)) {
      return true;
    }
    if (_shouldOpenBrowserPreview(state)) {
      final previewUrl = _resolveBrowserPreviewUrl(state);
      return previewUrl != null && previewUrl.isNotEmpty;
    }
    if (kIsWeb) {
      return false;
    }
    return state.capability?.canOpenExternal ?? false;
  }

  bool _supportsInlinePreview(FilePreviewState state) {
    final plan = state.openPlan;
    if (plan == null || !plan.shouldOpenInPage) {
      return false;
    }
    return switch (plan.renderStrategy) {
      FileRenderStrategy.nativeImage ||
      FileRenderStrategy.nativeVideo ||
      FileRenderStrategy.nativeAudio ||
      FileRenderStrategy.nativeText ||
      FileRenderStrategy.nativeMarkdown => true,
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.serverConvertedPdf ||
      FileRenderStrategy.serverConvertedHtml ||
      FileRenderStrategy.embeddedOfficeViewer => false,
      FileRenderStrategy.downloadOnly => false,
    };
  }

  Future<void> _previewFile(
    BuildContext context,
    FilePreviewState state,
  ) async {
    final strings = AppLocalizations.of(context);
    if (_supportsInlinePreview(state)) {
      setState(() {
        _previewVisible = true;
      });
      return;
    }
    if (_shouldOpenBrowserPreview(state)) {
      final previewUrl = _resolveBrowserPreviewUrl(state);
      if (previewUrl != null && previewUrl.isNotEmpty) {
        context.pushNamed(
          RouteNames.browser,
          extra: BrowserPageArgs(
            url: previewUrl,
            title: _previewTitle(state, strings),
            source: 'file',
          ),
        );
        return;
      }
    }
    final canOpenExternal = state.capability?.canOpenExternal ?? false;
    if (canOpenExternal) {
      await ref.read(filePreviewControllerProvider.notifier).openExternal();
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.filePreviewPreviewUnavailable)),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    try {
      await ref.read(filePreviewControllerProvider.notifier).download();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.filePreviewDownloadStarted)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.filePreviewDownloadFailed)),
      );
    }
  }

  void _forwardFile(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final messageId = widget.args.messageId?.trim() ?? '';
    if (messageId.isEmpty || messageId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.filePreviewForwardUnsupported)),
      );
      return;
    }
    context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(
        messageIds: <String>[messageId],
        initialForwardType: 1,
      ),
    );
  }

  bool _shouldOpenBrowserPreview(FilePreviewState state) {
    final isSupportedPlatform =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (!isSupportedPlatform) {
      return false;
    }
    return switch (state.openPlan?.renderStrategy) {
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.serverConvertedPdf ||
      FileRenderStrategy.serverConvertedHtml ||
      FileRenderStrategy.embeddedOfficeViewer => true,
      _ => false,
    };
  }

  String? _resolveBrowserPreviewUrl(FilePreviewState state) {
    final descriptor = state.descriptor;
    return descriptor?.previewUrl ??
        descriptor?.convertedPdfUrl ??
        descriptor?.viewerUrl;
  }

  String _previewTitle(FilePreviewState state, AppLocalizations strings) {
    final descriptorName = state.descriptor?.fileName.trim() ?? '';
    if (descriptorName.isNotEmpty) {
      return descriptorName;
    }
    final argsName = state.args?.fileName.trim() ?? '';
    if (argsName.isNotEmpty) {
      return argsName;
    }
    return strings.filePreviewTitle;
  }
}

class _FileDetailBody extends StatelessWidget {
  const _FileDetailBody({
    required this.state,
    required this.previewVisible,
    required this.onPreview,
    required this.onDownload,
  });

  final FilePreviewState state;
  final bool previewVisible;
  final VoidCallback? onPreview;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final descriptor = state.descriptor;
    final title = (descriptor?.fileName.trim().isNotEmpty ?? false)
        ? descriptor!.fileName.trim()
        : strings.filePreviewTitle;
    final ext = descriptor?.extension.trim().toUpperCase() ?? '';
    final sizeText = _formatFileSize(
      descriptor?.fileSize ?? state.args?.fileSize ?? 0,
    );
    final strategyText = _strategyLabel(strings, state);
    final message = state.openPlan?.fallbackMessage?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  ext.isNotEmpty ? ext : 'FILE',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202531),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sizeText  $strategyText',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.remove_red_eye_outlined),
                label: Text(strings.filePreviewPreview),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(strings.filePreviewDownload),
              ),
            ),
          ],
        ),
        if (previewVisible) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: FilePreviewBody(state: state),
          ),
        ],
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '--';
    }
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index += 1;
    }
    final fractionDigits = value >= 100 || index == 0 ? 0 : 1;
    return '${value.toStringAsFixed(fractionDigits)} ${units[index]}';
  }

  String _strategyLabel(AppLocalizations strings, FilePreviewState state) {
    return switch (state.openPlan?.renderStrategy) {
      FileRenderStrategy.nativePdf => strings.filePreviewModePdf,
      FileRenderStrategy.nativeImage => strings.filePreviewModeImage,
      FileRenderStrategy.nativeVideo => strings.filePreviewModeVideo,
      FileRenderStrategy.nativeAudio => strings.filePreviewModeAudio,
      FileRenderStrategy.nativeText => strings.filePreviewModeText,
      FileRenderStrategy.nativeMarkdown => strings.filePreviewModeMarkdown,
      FileRenderStrategy.serverConvertedPdf => strings.filePreviewModeServerPdf,
      FileRenderStrategy.serverConvertedHtml =>
        strings.filePreviewModeServerHtml,
      FileRenderStrategy.embeddedOfficeViewer => strings.filePreviewModeOffice,
      FileRenderStrategy.downloadOnly => strings.filePreviewModeDownloadOnly,
      null => strings.filePreviewModeUnknown,
    };
  }
}
