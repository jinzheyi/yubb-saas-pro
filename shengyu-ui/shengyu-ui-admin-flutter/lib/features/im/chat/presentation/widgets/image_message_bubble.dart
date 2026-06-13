import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ImageMessageBubble extends ConsumerWidget {
  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.onRetryMessage,
    required this.onOpenMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
    this.highlightKeyword,
    this.showFileName = false,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;
  final String? highlightKeyword;
  final bool showFileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final width = message.extra.width ?? 0;
    final height = message.extra.height ?? 0;
    final aspectRatio = width > 0 && height > 0 ? width / height : 1;
    final fileName = message.extra.fileName?.trim() ?? '';

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPressStart: onLongPressMessage == null
              ? null
              : (details) =>
                    onLongPressMessage!(message, details.globalPosition),
          child: InkWell(
            onTap: () => onOpenMessage(message),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 150,
              child: AspectRatio(
                aspectRatio: aspectRatio <= 0
                    ? 1
                    : aspectRatio.clamp(0.6, 1.6).toDouble(),
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.surfaceDim(context),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(message.isOutgoing ? 8 : 4),
                      bottomRight: Radius.circular(message.isOutgoing ? 4 : 8),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _buildImageContent(
                    context: context,
                    theme: theme,
                    strings: strings,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (fileName.isNotEmpty && showFileName)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildFileNameText(
              context: context,
              fileName: fileName,
              keyword: highlightKeyword,
            ),
          ),
        MessageStatusFooter(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        ),
      ],
    );
  }

  /// 构建图片内容：优先使用缓存加载，支持本地路径和网络 URL
  Widget _buildImageContent({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations strings,
  }) {
    final localPath = message.extra.localPath?.trim() ?? '';
    final remoteUrl = _resolveImageUrl();

    // 本地路径：使用 FileImage 或 MemoryImage
    if (localPath.isNotEmpty) {
      final imageProvider = _resolveLocalImageProvider(localPath);
      if (imageProvider != null) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    }

    // 远程 URL：使用 CachedNetworkImage（三级缓存）
    if (remoteUrl != null) {
      return CachedNetworkImage(
        imageUrl: remoteUrl,
        cacheManager: ImCacheManager.instance,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildPlaceholder(context, theme, strings),
        errorWidget: (context, url, error) => _buildPlaceholder(context, theme, strings),
      );
    }

    // 无有效图片源：显示占位符
    return _buildPlaceholder(context, theme, strings);
  }

  /// 解析图片 URL（优先缩略图，其次原图）
  String? _resolveImageUrl() {
    final thumbnailUrl = message.extra.thumbnailUrl?.trim() ?? '';
    if (thumbnailUrl.isNotEmpty && _isValidRemoteUrl(thumbnailUrl)) {
      return thumbnailUrl;
    }
    final fileUrl = message.extra.fileUrl?.trim() ?? '';
    if (fileUrl.isNotEmpty && _isValidRemoteUrl(fileUrl)) {
      return fileUrl;
    }
    final rawUrl = extractMediaUrlFromRawContent(message.content);
    if (rawUrl.isNotEmpty && _isValidRemoteUrl(rawUrl)) {
      return rawUrl;
    }
    return null;
  }

  /// 校验是否为有效的远程图片 URL
  bool _isValidRemoteUrl(String url) {
    if (url.startsWith('[') && url.endsWith(']')) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  /// 解析本地图片 Provider
  ImageProvider? _resolveLocalImageProvider(String localPath) {
    final uri = Uri.tryParse(localPath);
    final scheme = (uri?.scheme ?? '').toLowerCase();

    // data URI（base64 图片）
    if (scheme == 'data') {
      final commaIndex = localPath.indexOf(',');
      if (commaIndex > 0 && localPath.substring(0, commaIndex).contains(';base64')) {
        return MemoryImage(base64Decode(localPath.substring(commaIndex + 1)));
      }
      return NetworkImage(localPath);
    }
    // blob / http / https
    if (scheme == 'blob' || scheme == 'http' || scheme == 'https') {
      return NetworkImage(localPath);
    }
    // 本地文件路径（非 Web 平台）
    if (!kIsWeb) {
      return FileImage(File(localPath));
    }
    return null;
  }

  /// 构建占位符（加载中和无图片状态）
  Widget _buildPlaceholder(BuildContext context, ThemeData theme, AppLocalizations strings) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(
          AppIconKind.image,
          size: 30,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          strings.chatImagePlaceholder,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFileNameText({
    required BuildContext context,
    required String fileName,
    required String? keyword,
  }) {
    if (keyword == null || keyword.isEmpty) {
      return Text(
        fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: ThemeColors.textSecondary(context),
        ),
      );
    }
    final spans = _buildHighlightedSpans(
      context: context,
      text: fileName,
      keyword: keyword,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedSpans({
    required BuildContext context,
    required String text,
    required String keyword,
  }) {
    final spans = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    var lastEnd = 0;
    var startIndex = lowerText.indexOf(lowerKeyword);
    final defaultColor = ThemeColors.textSecondary(context);
    const highlightColor = Color(0xFF246BFD);

    while (startIndex >= 0) {
      if (startIndex > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, startIndex),
            style: TextStyle(color: defaultColor),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(startIndex, startIndex + keyword.length),
          style: const TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastEnd = startIndex + keyword.length;
      startIndex = lowerText.indexOf(lowerKeyword, lastEnd);
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(color: defaultColor),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: '', style: TextStyle(color: defaultColor)));
    }
    return spans;
  }
}
