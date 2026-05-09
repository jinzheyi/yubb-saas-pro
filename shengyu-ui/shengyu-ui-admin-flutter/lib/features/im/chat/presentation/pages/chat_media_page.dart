import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_media_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/providers/file_preview_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatMediaPage extends ConsumerStatefulWidget {
  const ChatMediaPage({super.key, required this.args});

  final ChatEntryArgs args;

  @override
  ConsumerState<ChatMediaPage> createState() => _ChatMediaPageState();
}

class _ChatMediaPageState extends ConsumerState<ChatMediaPage> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  _ChatMediaFilter _filter = _ChatMediaFilter.all;
  List<ChatMediaItem> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _noMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    Future.microtask(_loadMedia);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leadingWidth: 68,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const AppIcon(
            AppIconKind.chevronLeft,
            size: 22,
            color: Color(0xFF202531),
          ),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        title: Text(strings.chatMediaTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadMedia,
            icon: const AppIcon(
              AppIconKind.refresh,
              size: 20,
              color: Color(0xFF202531),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMedia,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _ChatMediaFilter.values)
                  _FilterChip(
                    label: filter.label(strings),
                    selected: _filter == filter,
                    onTap: () => _changeFilter(filter),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!, onRetry: _loadMedia)
            else if (_items.isEmpty)
              _EmptyCard(message: strings.chatMediaEmpty)
            else ...[
              for (final group in _buildDateGroups(strings)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                  child: Text(
                    group.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A1B2),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < group.items.length;
                        index++
                      ) ...[
                        ListTile(
                          onTap: () => _openItem(group.items[index]),
                          onLongPress: () => _showItemMenu(group.items[index]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: _MediaLeading(item: group.items[index]),
                          title: Text(
                            _displayName(group.items[index], strings),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202531),
                            ),
                          ),
                          subtitle: Text(
                            _buildSubtitle(group.items[index]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8F96A3),
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _showItemMenu(group.items[index]),
                            icon: const AppIcon(
                              AppIconKind.more,
                              size: 20,
                              color: Color(0xFFB8C0CC),
                            ),
                          ),
                        ),
                        if (index != group.items.length - 1)
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    _loadingMore
                        ? strings.chatMediaLoadingMore
                        : (_noMore
                              ? strings.chatMediaNoMore
                              : strings.chatMediaPullMore),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A1B2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadMedia({bool refresh = false, bool loadMore = false}) async {
    if (loadMore && (_loadingMore || _loading || _noMore)) {
      return;
    }
    if (!loadMore && !refresh && _loading) {
      return;
    }
    final nextPage = loadMore ? (_items.length ~/ _pageSize) + 1 : 1;
    setState(() {
      _errorMessage = null;
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });
    try {
      final items = await ref
          .read(messageRepositoryProvider)
          .getChatMedia(
            chatId: widget.args.chatId,
            fileType: _filter.apiValue,
            pageNo: nextPage,
            pageSize: _pageSize,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = loadMore ? <ChatMediaItem>[..._items, ...items] : items;
        _loading = false;
        _loadingMore = false;
        _noMore = items.length < _pageSize;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _changeFilter(_ChatMediaFilter filter) {
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _items = const [];
      _loading = true;
      _loadingMore = false;
      _noMore = false;
    });
    _loadMedia();
  }

  void _openItem(ChatMediaItem item) {
    final fileId = item.fileId.trim().isNotEmpty ? item.fileId : item.messageId;
    if (fileId.isEmpty) {
      return;
    }
    if (_filter == _ChatMediaFilter.image ||
        item.messageType == MessageType.image) {
      _previewImageItem(item);
      return;
    }
    if (_filter == _ChatMediaFilter.video ||
        item.messageType == MessageType.video) {
      context.pushNamed(
        RouteNames.chatVideoPlayer,
        extra: VideoPlayerRouteArgs(
          url: item.fileUrl,
          fileId: fileId,
          title: _displayName(item, AppLocalizations.of(context)),
        ),
      );
      return;
    }
    context.pushNamed(
      RouteNames.filePreview,
      extra: FilePreviewRouteArgs(
        fileId: fileId,
        fileName: _displayName(item, AppLocalizations.of(context)),
        mimeType: item.mimeType.isNotEmpty
            ? item.mimeType
            : _fallbackMimeType(item),
        fileSize: item.fileSize,
        messageId: item.messageId,
        chatId: item.chatId,
        sourceType: switch (_filter) {
          _ChatMediaFilter.image => 'image',
          _ChatMediaFilter.video => 'video',
          _ => 'file',
        },
      ),
    );
  }

  Future<void> _previewImageItem(ChatMediaItem item) async {
    final imageItems = _items.where(_isImageItem).toList(growable: false);
    if (imageItems.isEmpty) {
      return;
    }
    final selectedIndex = imageItems.indexWhere(
      (candidate) => candidate.messageId == item.messageId,
    );
    final initialIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final urls = await Future.wait(
      imageItems.map(_resolvePreviewUrl),
      eagerError: false,
    );
    final previewUrls = urls
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (!mounted || previewUrls.isEmpty) {
      return;
    }
    final effectiveIndex = initialIndex.clamp(0, previewUrls.length - 1);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'chat-media-image-preview',
      barrierColor: Colors.black,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final pageController = PageController(initialPage: effectiveIndex);
        return Material(
          color: Colors.black,
          child: GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Center(
              child: PageView.builder(
                controller: pageController,
                itemCount: previewUrls.length,
                itemBuilder: (context, index) {
                  final url = previewUrls[index];
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(
                          url,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshMedia() async {
    await _loadMedia(refresh: true);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || _noMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _loadMedia(loadMore: true);
    }
  }

  Future<void> _showItemMenu(ChatMediaItem item) async {
    final strings = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(
                  AppIconKind.download,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: Text(strings.groupFilesActionDownload),
                onTap: () => Navigator.of(dialogContext).pop('download'),
              ),
              ListTile(
                leading: const AppIcon(
                  AppIconKind.arrowForward,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: Text(strings.groupFilesActionForward),
                onTap: () => Navigator.of(dialogContext).pop('forward'),
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
        await _downloadItem(item);
        break;
      case 'forward':
        _forwardItem(item);
        break;
    }
  }

  Future<void> _downloadItem(ChatMediaItem item) async {
    final strings = AppLocalizations.of(context);
    try {
      final url = await _resolvePreviewUrl(item);
      if (url.isEmpty) {
        throw StateError('missing file url');
      }
      await ref.read(fileDownloadServiceProvider).download(Uri.parse(url));
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

  void _forwardItem(ChatMediaItem item) {
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

  List<_MediaDateGroup> _buildDateGroups(AppLocalizations strings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <_MediaDateGroup>[];
    _MediaDateGroup? currentGroup;
    for (final item in _items) {
      final sentAt = item.sentAt?.toLocal() ?? now;
      final normalized = DateTime(sentAt.year, sentAt.month, sentAt.day);
      final label = switch (normalized) {
        _ when normalized == today => strings.chatMediaToday,
        _ when normalized == yesterday => strings.chatMediaYesterday,
        _ => strings.chatMediaMonthDay(
          sentAt.month.toString().padLeft(2, '0'),
          sentAt.day.toString().padLeft(2, '0'),
        ),
      };
      if (currentGroup == null || currentGroup.label != label) {
        currentGroup = _MediaDateGroup(
          label: label,
          items: <ChatMediaItem>[item],
        );
        groups.add(currentGroup);
      } else {
        currentGroup.items.add(item);
      }
    }
    return groups;
  }

  Future<String> _resolvePreviewUrl(ChatMediaItem item) async {
    final fileId = item.fileId.trim().isNotEmpty ? item.fileId : item.messageId;
    if (fileId.isNotEmpty) {
      try {
        final signed = await ref
            .read(fileRepositoryProvider)
            .getPresignedGetUrl(fileId: fileId);
        return signed.toString();
      } catch (_) {}
    }
    return item.fileUrl.trim();
  }

  String _displayName(ChatMediaItem item, AppLocalizations strings) {
    if (item.fileName.trim().isNotEmpty) {
      return item.fileName.trim();
    }
    return switch (item.messageType) {
      MessageType.image => strings.chatMediaImageFallback,
      _ => strings.chatMediaFileFallback,
    };
  }

  String _buildSubtitle(ChatMediaItem item) {
    final parts = <String>[
      if (item.senderName.trim().isNotEmpty) item.senderName.trim(),
      if (item.fileSize > 0) _formatFileSize(item.fileSize),
      if (item.sentAt != null)
        DateFormat('yyyy-MM-dd HH:mm').format(item.sentAt!.toLocal()),
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

  String _fallbackMimeType(ChatMediaItem item) {
    final isVideo = _isVideoItem(item);
    return switch (_filter) {
      _ChatMediaFilter.image => 'image/*',
      _ChatMediaFilter.video => 'video/*',
      _ => isVideo ? 'video/*' : 'application/octet-stream',
    };
  }

  bool _isVideoItem(ChatMediaItem item) {
    if (item.mimeType.startsWith('video/')) {
      return true;
    }
    final fileName = item.fileName.trim().toLowerCase();
    return fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.m4v') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm');
  }

  bool _isImageItem(ChatMediaItem item) {
    if (item.messageType == MessageType.image) {
      return true;
    }
    return item.mimeType.startsWith('image/');
  }
}

class _MediaDateGroup {
  _MediaDateGroup({required this.label, required this.items});

  final String label;
  final List<ChatMediaItem> items;
}

enum _ChatMediaFilter {
  all(null),
  image('image'),
  video('video'),
  file('file');

  const _ChatMediaFilter(this.apiValue);

  final String? apiValue;

  String label(AppLocalizations strings) {
    return switch (this) {
      _ChatMediaFilter.all => strings.groupHistoryFilterAll,
      _ChatMediaFilter.image => strings.groupHistoryFilterImage,
      _ChatMediaFilter.video => strings.chatMediaFilterVideo,
      _ChatMediaFilter.file => strings.groupHistoryFilterFile,
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF246BFD) : const Color(0xFFE5EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? const Color(0xFF246BFD) : const Color(0xFF5B6475),
          ),
        ),
      ),
    );
  }
}

class _MediaLeading extends StatelessWidget {
  const _MediaLeading({required this.item});

  final ChatMediaItem item;

  @override
  Widget build(BuildContext context) {
    final isImage = item.messageType == MessageType.image;
    final isVideo = _isVideoItem(item);
    final imageUrl = isVideo
        ? item.thumbnailUrl
        : (item.thumbnailUrl.isNotEmpty ? item.thumbnailUrl : item.fileUrl);
    if (isImage && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const _FileIconBox(icon: AppIconKind.image);
          },
        ),
      );
    }
    if (isVideo && imageUrl.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const _FileIconBox(icon: AppIconKind.video);
              },
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xA6000000),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              AppIconKind.play,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      );
    }
    return _FileIconBox(icon: isVideo ? AppIconKind.video : AppIconKind.file);
  }

  bool _isVideoItem(ChatMediaItem item) {
    if (item.mimeType.startsWith('video/')) {
      return true;
    }
    final fileName = item.fileName.trim().toLowerCase();
    return fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.m4v') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm');
  }
}

class _FileIconBox extends StatelessWidget {
  const _FileIconBox({required this.icon});

  final AppIconKind icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: AppIcon(icon, size: 22, color: const Color(0xFF246BFD)),
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
