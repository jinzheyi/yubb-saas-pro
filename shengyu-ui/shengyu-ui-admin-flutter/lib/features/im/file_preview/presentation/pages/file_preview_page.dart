import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_action.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_status.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
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
    final canDownload = state.capability?.canDownload ?? false;
    final canOpenExternal = state.capability?.canOpenExternal ?? false;
    final title = (state.args?.fileName.trim().isNotEmpty ?? false)
        ? state.args!.fileName.trim()
        : strings.filePreviewTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: pending || !canDownload
                ? null
                : () {
                    ref.read(filePreviewControllerProvider.notifier).download();
                  },
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            onPressed: pending || !canOpenExternal
                ? null
                : () {
                    ref
                        .read(filePreviewControllerProvider.notifier)
                        .openExternal();
                  },
            icon: const Icon(Icons.open_in_new_rounded),
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
        FilePreviewStatus.downloadOnly => Center(
          child: FilledButton.icon(
            onPressed: () {
              ref.read(filePreviewControllerProvider.notifier).download();
            },
            icon: const Icon(Icons.download_rounded),
            label: Text(strings.filePreviewDownload),
          ),
        ),
        FilePreviewStatus.rendering => FilePreviewBody(state: state),
      },
    );
  }
}
