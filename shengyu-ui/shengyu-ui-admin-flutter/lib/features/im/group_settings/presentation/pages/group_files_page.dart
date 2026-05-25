import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_file_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';

class GroupFilesPage extends ConsumerStatefulWidget {
  const GroupFilesPage({super.key, required this.args});

  final GroupSettingDetailArgs args;

  @override
  ConsumerState<GroupFilesPage> createState() => _GroupFilesPageState();
}

class _GroupFilesPageState extends ConsumerState<GroupFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupFileItem> _files = const [];
  bool _loading = true;
  String? _errorMessage;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        context.go(RoutePaths.conversations);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: () => context.go(RoutePaths.conversations),
          ),
        centerTitle: true,
        title: Text(strings.groupSettingsGroupFiles),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadFiles,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadFiles(),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: Color(0xFF98A1B2),
                ),
                hintText: strings.groupFilesSearch,
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: _loadFiles,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF98A1B2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _ErrorCard(message: _errorMessage!, onRetry: _loadFiles)
          else if (_files.isEmpty)
            _EmptyCard(message: strings.groupFilesEmpty)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < _files.length; index++) ...[
                    _buildFileTile(_files[index]),
                    if (index != _files.length - 1)
                      const Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: Color(0xFFF0F2F6),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
    );
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final files = await ref
          .read(groupSettingsRepositoryProvider)
          .getGroupFiles(
            groupId: widget.args.groupId,
            keyword: _searchController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _deleteFile(GroupFileItem item) async {
    setState(() {
      _deletingId = item.id;
    });
    try {
      await ref.read(groupSettingsRepositoryProvider).deleteGroupFile(item.id);
      if (!mounted) {
        return;
      }
      await _loadFiles();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingId = null;
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _deletingId = null;
        });
      }
    }
  }

  void _openFilePreview(GroupFileItem item) {
    final fileId = item.fileId.trim().isNotEmpty ? item.fileId : item.id;
    if (fileId.isEmpty) {
      return;
    }
    if (_isImageItem(item)) {
      _previewImageItem(fileId);
      return;
    }
    if (_isVideoItem(item)) {
      context.pushNamed(
        RouteNames.chatVideoPlayer,
        extra: VideoPlayerRouteArgs(
          url: item.fileUrl,
          fileId: fileId,
          title: item.fileName,
        ),
      );
      return;
    }
    context.pushNamed(
      RouteNames.filePreview,
      extra: FilePreviewRouteArgs(
        fileId: fileId,
        fileName: item.fileName,
        mimeType: item.mimeType.isEmpty
            ? 'application/octet-stream'
            : item.mimeType,
        fileSize: item.fileSize,
        sourceType: 'file',
      ),
    );
  }

  Future<void> _showFileMenu(GroupFileItem item) async {
    final strings = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(strings.groupFilesActionDownload),
                onTap: () => Navigator.of(dialogContext).pop('download'),
              ),
              ListTile(
                leading: const Icon(Icons.forward_rounded),
                title: Text(strings.groupFilesActionForward),
                onTap: () => Navigator.of(dialogContext).pop('forward'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(strings.chatActionDelete),
                onTap: () => Navigator.of(dialogContext).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case 'download':
        await _downloadFile(item);
        break;
      case 'forward':
        _forwardFile(item);
        break;
      case 'delete':
        await _deleteFile(item);
        break;
    }
  }

  Future<void> _downloadFile(GroupFileItem item) async {
    final strings = AppLocalizations.of(context);
    try {
      Uri uri;
      if (item.fileUrl.trim().isNotEmpty) {
        uri = Uri.parse(item.fileUrl.trim());
      } else {
        final fileId = item.fileId.trim().isNotEmpty ? item.fileId : item.id;
        if (fileId.isEmpty) {
          throw StateError('missing file id');
        }
        uri = await ref
            .read(fileRepositoryProvider)
            .getPresignedGetUrl(fileId: fileId);
      }
      await ref
          .read(fileDownloadServiceProvider)
          .download(uri, suggestedFileName: item.fileName);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupFilesDownloadStarted)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.groupFilesDownloadFailed)));
    }
  }

  void _forwardFile(GroupFileItem item) {
    final strings = AppLocalizations.of(context);
    final messageId = item.messageId.trim();
    if (messageId.isEmpty || messageId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupFilesForwardUnsupported)),
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

  Future<void> _previewImageItem(String fileId) async {
    try {
      final signed = await ref
          .read(fileRepositoryProvider)
          .getPresignedGetUrl(fileId: fileId);
      if (!mounted) {
        return;
      }
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'group-file-image-preview',
        barrierColor: Colors.black,
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Material(
            color: Colors.black,
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    signed.toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        signed.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  bool _isImageItem(GroupFileItem item) {
    final mediaType = item.mediaType.trim().toLowerCase();
    final mimeType = item.mimeType.trim().toLowerCase();
    return mediaType == 'image' || mimeType.startsWith('image/');
  }

  bool _isVideoItem(GroupFileItem item) {
    final mediaType = item.mediaType.trim().toLowerCase();
    final mimeType = item.mimeType.trim().toLowerCase();
    return mediaType == 'video' || mimeType.startsWith('video/');
  }

  String _buildSubtitle(GroupFileItem item) {
    final parts = <String>[
      _formatFileSize(item.fileSize),
      if (item.uploaderName.trim().isNotEmpty) item.uploaderName.trim(),
      if (item.uploadedAt != null)
        DateFormat('yyyy-MM-dd HH:mm').format(item.uploadedAt!.toLocal()),
    ];
    return parts.join(' · ');
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    final text = size >= 10 || index == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$text ${units[index]}';
  }

  Widget _buildFileTile(GroupFileItem item) {
    final iconSpec = resolveShengyuFileIcon(
      item.mimeType,
      fileName: item.fileName,
    );
    return ListTile(
      onTap: () => _openFilePreview(item),
      onLongPress: () => _showFileMenu(item),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconSpec.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(iconSpec.icon, color: iconSpec.color, size: 20),
      ),
      title: Text(
        item.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF202531),
        ),
      ),
      subtitle: Text(
        _buildSubtitle(item),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8F96A3)),
      ),
      trailing: _deletingId == item.id
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              onPressed: () => _showFileMenu(item),
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFFB8C0CC),
              ),
            ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(strings.retry)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(fontSize: 15, color: Color(0xFF8F96A3)),
      ),
    );
  }
}
