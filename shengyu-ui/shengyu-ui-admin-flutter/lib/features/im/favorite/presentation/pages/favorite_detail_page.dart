import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/favorite_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_detail.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class FavoriteDetailPage extends ConsumerStatefulWidget {
  const FavoriteDetailPage({super.key, required this.args});

  final FavoriteDetailRouteArgs args;

  @override
  ConsumerState<FavoriteDetailPage> createState() => _FavoriteDetailPageState();
}

class _FavoriteDetailPageState extends ConsumerState<FavoriteDetailPage> {
  bool _loading = true;
  FavoriteDetail? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final detail = _detail;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(title: Text(strings.favoriteDetailTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          strings.favoriteDetailLoading,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ),
                    )
                  : detail == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          strings.favoriteDetailEmpty,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ),
                    )
                  : _FavoriteDetailBody(
                      detail: detail,
                      onPreviewImage: _previewImage,
                      onOpenVideo: _openVideo,
                      onOpenFile: _openFile,
                      onOpenLink: _openLink,
                      onOpenLocation: _openLocation,
                    ),
            ),
          ),
          if (detail != null)
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton(
                    onPressed: _sendToChat,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF246BFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(strings.favoriteDetailSendToChat),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadDetail() async {
    final strings = AppLocalizations.of(context);
    final favoriteId = widget.args.favoriteId.trim();
    if (favoriteId.isEmpty || favoriteId == '0') {
      _showNotice(strings.favoriteDetailInvalidId);
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final detail = await ref
          .read(favoriteRepositoryProvider)
          .getFavoriteDetail(favoriteId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showNotice(strings.favoriteDetailLoadFailed);
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _previewImage(String url) async {
    if (url.trim().isEmpty) {
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'favorite-image-preview',
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFile(_FavoriteRenderData data) {
    final strings = AppLocalizations.of(context);
    if (data.fileId.isEmpty && data.url.isEmpty) {
      _showNotice(strings.favoriteDetailFileUrlEmpty);
      return;
    }
    context.pushNamed(
      RouteNames.filePreview,
      extra: FilePreviewRouteArgs(
        fileId: data.fileId,
        fileName: data.fileName.isNotEmpty ? data.fileName : data.title,
        mimeType: data.mimeType,
        fileSize: data.fileSizeValue,
        fileUrl: data.url.isEmpty ? null : data.url,
        sourceType: data.kind.name,
      ),
    );
  }

  void _openVideo(_FavoriteRenderData data) {
    final strings = AppLocalizations.of(context);
    if (data.url.isEmpty && data.fileId.isEmpty) {
      _showNotice(strings.favoriteDetailVideoUrlEmpty);
      return;
    }
    context.pushNamed(
      RouteNames.chatVideoPlayer,
      extra: VideoPlayerRouteArgs(
        url: data.url,
        fileId: data.fileId,
        title: data.title,
      ),
    );
  }

  void _openLink(String url, String title) {
    final finalUrl = _ensureLinkScheme(url);
    if (finalUrl.isEmpty) {
      return;
    }
    if (kIsWeb) {
      unawaited(_openLinkOnWebFirst(finalUrl, title));
      return;
    }
    context.pushNamed(
      RouteNames.browser,
      extra: BrowserPageArgs(url: finalUrl, title: title, source: 'external'),
    );
  }

  Future<void> _openLinkOnWebFirst(String url, String title) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final opened = await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
          mode: LaunchMode.platformDefault,
        );
        if (opened || !mounted) {
          return;
        }
      } catch (_) {}
    }
    if (!mounted) {
      return;
    }
    context.pushNamed(
      RouteNames.browser,
      extra: BrowserPageArgs(url: url, title: title, source: 'external'),
    );
  }

  Future<void> _openLocation(_FavoriteRenderData data) async {
    final strings = AppLocalizations.of(context);
    if (data.latitude == null || data.longitude == null) {
      _showNotice(strings.chatLocationMissing);
      return;
    }
    final latitude = data.latitude!;
    final longitude = data.longitude!;
    final opened = await ref
        .read(chatLocationOpenerServiceProvider)
        .open(
          latitude: latitude,
          longitude: longitude,
          name: data.title,
          address: data.text,
        );
    if (opened || !mounted) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(
        text: _buildLocationClipboardPayload(
          locationName: data.title,
          address: data.text,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
    if (mounted) {
      _showNotice(strings.chatLocationCopied);
    }
  }

  void _sendToChat() {
    final strings = AppLocalizations.of(context);
    final favoriteId = widget.args.favoriteId.trim();
    if (favoriteId.isEmpty || favoriteId == '0') {
      _showNotice(strings.favoriteDetailInvalidId);
      return;
    }
    context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(favoriteId: favoriteId),
    );
  }

  String _buildLocationClipboardPayload({
    required String locationName,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final parts = <String>[];
    if (locationName.trim().isNotEmpty) {
      parts.add(locationName.trim());
    }
    if (address.trim().isNotEmpty && address.trim() != locationName.trim()) {
      parts.add(address.trim());
    }
    parts.add(
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
    );
    return parts.join('\n');
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FavoriteDetailBody extends StatelessWidget {
  const _FavoriteDetailBody({
    required this.detail,
    required this.onPreviewImage,
    required this.onOpenVideo,
    required this.onOpenFile,
    required this.onOpenLink,
    required this.onOpenLocation,
  });

  final FavoriteDetail detail;
  final Future<void> Function(String url) onPreviewImage;
  final void Function(_FavoriteRenderData data) onOpenVideo;
  final void Function(_FavoriteRenderData data) onOpenFile;
  final void Function(String url, String title) onOpenLink;
  final Future<void> Function(_FavoriteRenderData data) onOpenLocation;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final renderData = _buildRenderData(strings, detail);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  renderData.typeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A93A0),
                  ),
                ),
              ),
              Text(
                _formatFavoriteTime(detail.favoriteTime, detail.sendTime),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          switch (renderData.kind) {
            _FavoriteRenderKind.image => GestureDetector(
              onTap: () => onPreviewImage(renderData.url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  renderData.url,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, _, _) =>
                      _FallbackText(text: renderData.url),
                ),
              ),
            ),
            _FavoriteRenderKind.video => GestureDetector(
              onTap: () => onOpenVideo(renderData),
              child: _VideoBlock(data: renderData),
            ),
            _FavoriteRenderKind.file => GestureDetector(
              onTap: () => onOpenFile(renderData),
              child: _InfoBlock(
                data: renderData,
                icon: Icons.insert_drive_file_outlined,
              ),
            ),
            _FavoriteRenderKind.link => GestureDetector(
              onTap: () => onOpenLink(renderData.url, renderData.title),
              child: _LinkBlock(data: renderData),
            ),
            _FavoriteRenderKind.location => GestureDetector(
              onTap: () => onOpenLocation(renderData),
              child: _InfoBlock(data: renderData, icon: Icons.place_outlined),
            ),
            _ => Text(
              renderData.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF202531),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  const _VideoBlock({required this.data});

  final _FavoriteRenderData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: const Color(0xFF111111),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (data.thumb.isNotEmpty)
                  Image.network(
                    data.thumb,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _videoFallback(),
                  )
                else
                  _videoFallback(),
                Container(
                  width: double.infinity,
                  height: 190,
                  color: const Color(0x33000000),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (data.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Text(
                  data.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD4D9E1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _videoFallback() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.data, required this.icon});

  final _FavoriteRenderData data;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFD),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: const Color(0xFF4B70D0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.fileName.isNotEmpty ? data.fileName : data.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF202531),
                  ),
                ),
                if (data.fileSize.isNotEmpty || data.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.fileSize.isNotEmpty ? data.fileSize : data.text,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A93A0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkBlock extends StatelessWidget {
  const _LinkBlock({required this.data});

  final _FavoriteRenderData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF202531)),
          ),
          const SizedBox(height: 6),
          Text(
            data.url,
            style: const TextStyle(fontSize: 13, color: Color(0xFF3765C9)),
          ),
        ],
      ),
    );
  }
}

class _FallbackText extends StatelessWidget {
  const _FallbackText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF202531)),
      ),
    );
  }
}

enum _FavoriteRenderKind { text, image, video, file, link, location }

class _FavoriteRenderData {
  const _FavoriteRenderData({
    required this.kind,
    required this.typeLabel,
    required this.text,
    required this.title,
    required this.url,
    required this.fileId,
    required this.thumb,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.fileSizeValue,
    this.latitude,
    this.longitude,
  });

  final _FavoriteRenderKind kind;
  final String typeLabel;
  final String text;
  final String title;
  final String url;
  final String fileId;
  final String thumb;
  final String fileName;
  final String fileSize;
  final String mimeType;
  final int fileSizeValue;
  final double? latitude;
  final double? longitude;
}

_FavoriteRenderData _buildRenderData(
  AppLocalizations strings,
  FavoriteDetail item,
) {
  final parsedContent = _safeParseJson(item.messageContent);
  final parsedExtra = _safeParseJson(item.messageExtra);
  final parsedSnapshot = _safeParseJson(item.messageSnapshot);
  final snapshotContent = parsedSnapshot is Map<String, dynamic>
      ? _safeParseJson(parsedSnapshot['content'])
      : null;
  final snapshotExtra = parsedSnapshot is Map<String, dynamic>
      ? _safeParseJson(parsedSnapshot['extra'])
      : null;

  final fallbackText = item.messagePreview.isNotEmpty
      ? item.messagePreview
      : strings.chatPreviewMessage;
  final fallback = _FavoriteRenderData(
    kind: _FavoriteRenderKind.text,
    typeLabel: strings.favoriteDetailTypeDefault,
    text: fallbackText,
    title: fallbackText,
    url: '',
    fileId: '',
    thumb: '',
    fileName: '',
    fileSize: '',
    mimeType: '',
    fileSizeValue: 0,
  );

  if (item.messageType == 1) {
    final textContent = _extractText(
      parsedContent ?? item.messageContent,
    ).trim();
    if (_looksLikeLinkContent(textContent)) {
      return _FavoriteRenderData(
        kind: _FavoriteRenderKind.link,
        typeLabel: strings.favoriteDetailTypeLink,
        text: textContent,
        title: textContent,
        url: _ensureLinkScheme(textContent),
        fileId: '',
        thumb: '',
        fileName: '',
        fileSize: '',
        mimeType: '',
        fileSizeValue: 0,
      );
    }
    final text = textContent.isNotEmpty ? textContent : fallback.text;
    return _FavoriteRenderData(
      kind: _FavoriteRenderKind.text,
      typeLabel: strings.favoriteDetailTypeNote,
      text: text,
      title: text,
      url: '',
      fileId: '',
      thumb: '',
      fileName: '',
      fileSize: '',
      mimeType: '',
      fileSizeValue: 0,
    );
  }

  if (item.messageType == 2) {
    final url =
        _resolveUrlFromObject(parsedContent) ??
        _resolveUrlFromObject(parsedExtra) ??
        _resolveUrlFromObject(snapshotContent) ??
        _resolveUrlFromObject(snapshotExtra) ??
        item.messageContent.trim();
    return _FavoriteRenderData(
      kind: _FavoriteRenderKind.image,
      typeLabel: strings.favoriteDetailTypeImage,
      text: fallback.text,
      title: item.messagePreview.isNotEmpty
          ? item.messagePreview
          : strings.chatPreviewImage,
      url: url,
      fileId: '',
      thumb: '',
      fileName: '',
      fileSize: '',
      mimeType: '',
      fileSizeValue: 0,
    );
  }

  if (item.messageType == 4) {
    final url =
        _resolveUrlFromObject(parsedContent) ??
        _resolveUrlFromObject(parsedExtra) ??
        _resolveUrlFromObject(snapshotContent) ??
        _resolveUrlFromObject(snapshotExtra) ??
        item.messageContent.trim();
    final cover = parsedExtra is Map<String, dynamic>
        ? (parsedExtra['cover']?.toString() ??
              parsedExtra['thumbnail']?.toString() ??
              parsedExtra['thumbUrl']?.toString() ??
              '')
        : '';
    return _FavoriteRenderData(
      kind: _FavoriteRenderKind.video,
      typeLabel: strings.favoriteDetailTypeVideo,
      text: fallback.text,
      title: item.messagePreview.isNotEmpty
          ? item.messagePreview
          : strings.chatPreviewVideo,
      url: url,
      fileId:
          _resolveFileIdFromObject(parsedExtra) ??
          _resolveFileIdFromObject(parsedContent) ??
          '',
      thumb: cover,
      fileName: '',
      fileSize: '',
      mimeType: '',
      fileSizeValue: 0,
    );
  }

  if (item.messageType == 5) {
    final fileObj = parsedExtra is Map<String, dynamic>
        ? parsedExtra
        : (snapshotExtra is Map<String, dynamic> ? snapshotExtra : null);
    final fileUrl =
        _resolveUrlFromObject(fileObj) ??
        _resolveUrlFromObject(parsedContent) ??
        _resolveUrlFromObject(snapshotContent) ??
        item.messageContent.trim();
    final fileId =
        _resolveFileIdFromObject(fileObj) ??
        _resolveFileIdFromObject(parsedContent) ??
        _resolveFileIdFromObject(snapshotContent) ??
        _resolveFileIdFromObject(snapshotExtra) ??
        '';
    final fileName =
        fileObj?['fileName']?.toString() ??
        (item.messagePreview.isNotEmpty
            ? item.messagePreview
            : strings.chatPreviewFile);
    final fileSizeRaw = fileObj?['size'];
    final fileSize = fileSizeRaw is num
        ? _buildFileSizeText(fileSizeRaw.toInt())
        : '';
    final mimeType =
        fileObj?['fileType']?.toString() ??
        fileObj?['mimeType']?.toString() ??
        '';
    return _FavoriteRenderData(
      kind: _FavoriteRenderKind.file,
      typeLabel: strings.favoriteDetailTypeFile,
      text: fallback.text,
      title: fileName,
      url: fileUrl,
      fileId: fileId,
      thumb: '',
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      fileSizeValue: fileSizeRaw is num ? fileSizeRaw.toInt() : 0,
    );
  }

  if (item.messageType == 6) {
    final locationObj = parsedContent is Map<String, dynamic>
        ? parsedContent
        : (snapshotContent is Map<String, dynamic> ? snapshotContent : null);
    final latitude = _toDouble(locationObj?['latitude']);
    final longitude = _toDouble(locationObj?['longitude']);
    final address = locationObj?['address']?.toString() ?? '';
    final locationName =
        locationObj?['name']?.toString() ??
        locationObj?['locationName']?.toString() ??
        address;
    return _FavoriteRenderData(
      kind: _FavoriteRenderKind.location,
      typeLabel: strings.chatPreviewLocation,
      text: address.isNotEmpty
          ? address
          : strings.chatLocationCoordinateFallback(
              latitude?.toStringAsFixed(6) ?? '-',
              longitude?.toStringAsFixed(6) ?? '-',
            ),
      title: locationName.isNotEmpty
          ? locationName
          : strings.chatLocationDefaultTitle,
      url: '',
      fileId: '',
      thumb: '',
      fileName: '',
      fileSize: '',
      mimeType: '',
      fileSizeValue: 0,
      latitude: latitude,
      longitude: longitude,
    );
  }

  if (item.messageType == 9) {
    final customObj = parsedContent is Map<String, dynamic>
        ? parsedContent
        : (parsedExtra is Map<String, dynamic> ? parsedExtra : null);
    final customType = customObj?['type']?.toString().toUpperCase() ?? '';
    final customUrl =
        _resolveUrlFromObject(customObj) ??
        _resolveUrlFromObject(snapshotContent) ??
        _resolveUrlFromObject(snapshotExtra) ??
        '';
    if (customType == 'LINK' ||
        customType == 'URL' ||
        customType == 'WEB_LINK' ||
        customUrl.isNotEmpty) {
      final title = customObj?['title']?.toString() ?? '';
      return _FavoriteRenderData(
        kind: _FavoriteRenderKind.link,
        typeLabel: strings.favoriteDetailTypeLink,
        text: fallback.text,
        title: title.isNotEmpty
            ? title
            : (customUrl.isNotEmpty ? customUrl : fallback.title),
        url: _ensureLinkScheme(customUrl),
        fileId: '',
        thumb: '',
        fileName: '',
        fileSize: '',
        mimeType: '',
        fileSizeValue: 0,
      );
    }
  }

  return fallback;
}

Object? _safeParseJson(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is! String) {
    return null;
  }
  final text = raw.trim();
  if (text.isEmpty ||
      ((!text.startsWith('{') || !text.endsWith('}')) &&
          (!text.startsWith('[') || !text.endsWith(']')))) {
    return null;
  }
  try {
    return jsonDecode(text);
  } catch (_) {
    return null;
  }
}

String _extractText(Object? raw) {
  if (raw == null) {
    return '';
  }
  if (raw is String) {
    return raw;
  }
  if (raw is Map) {
    final content = raw['content']?.toString() ?? '';
    if (content.isNotEmpty) {
      return content;
    }
    final text = raw['text']?.toString() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
    return raw['title']?.toString() ?? '';
  }
  return '';
}

bool _looksLikeLinkContent(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return false;
  }
  return RegExp(r'^https?:\/\/\S+$', caseSensitive: false).hasMatch(value) ||
      RegExp(r'^www\.\S+$', caseSensitive: false).hasMatch(value);
}

String _ensureLinkScheme(String raw) {
  final url = raw.trim();
  if (url.isEmpty) {
    return '';
  }
  if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(url)) {
    return url;
  }
  if (RegExp(r'^www\.', caseSensitive: false).hasMatch(url)) {
    return 'https://$url';
  }
  return url;
}

String? _resolveUrlFromObject(Object? obj) {
  if (obj is! Map) {
    return null;
  }
  for (final key in const ['url', 'link', 'href']) {
    final value = obj[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  final nested = obj['content'];
  if (nested is String && _looksLikeLinkContent(nested.trim())) {
    return nested.trim();
  }
  return _resolveUrlFromObject(nested);
}

String? _resolveFileIdFromObject(Object? obj) {
  if (obj is! Map) {
    return null;
  }
  for (final key in const ['fileId', 'file_id']) {
    final value = obj[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value != '0') {
      return value;
    }
  }
  return _resolveFileIdFromObject(obj['content']);
}

double? _toDouble(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(raw?.toString() ?? '');
}

String _buildFileSizeText(int size) {
  if (size <= 0) {
    return '';
  }
  if (size < 1024) {
    return '${size}B';
  }
  if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)}KB';
  }
  if (size < 1024 * 1024 * 1024) {
    return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
  }
  return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
}

String _formatFavoriteTime(String favoriteTime, String sendTime) {
  final raw = favoriteTime.trim().isNotEmpty
      ? favoriteTime.trim()
      : sendTime.trim();
  if (raw.isEmpty) {
    return '';
  }
  DateTime? date = DateTime.tryParse(
    raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw,
  );
  final number = int.tryParse(raw);
  if (date == null && number != null && number > 0) {
    final milliseconds = raw.length <= 10 ? number * 1000 : number;
    date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  if (date == null) {
    return raw;
  }
  if (date.year == DateTime.now().year) {
    return '${date.month}-${date.day}';
  }
  return '${date.year}-${date.month}-${date.day}';
}
