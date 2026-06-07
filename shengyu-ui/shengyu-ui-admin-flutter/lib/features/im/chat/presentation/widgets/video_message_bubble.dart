import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/chat_image_provider_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class VideoMessageBubble extends ConsumerWidget {
  const VideoMessageBubble({
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
    final imageProvider = _resolveVideoPreviewImageProvider();
    final fileName = message.extra.fileName?.trim() ?? '';

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.isOutgoing)
          _OutgoingStatusRow(message: message, onRetryMessage: onRetryMessage),
        const SizedBox(height: 4),
        GestureDetector(
          onLongPressStart: onLongPressMessage == null
              ? null
              : (details) =>
                    onLongPressMessage!(message, details.globalPosition),
          child: InkWell(
            onTap: () => onOpenMessage(message),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(message.isOutgoing ? 8 : 4),
                  bottomRight: Radius.circular(message.isOutgoing ? 4 : 8),
                ),
                image: imageProvider == null
                    ? null
                    : DecorationImage(image: imageProvider, fit: BoxFit.contain),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (imageProvider == null)
                    Text(
                      strings.chatImagePlaceholder,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      AppIconKind.play,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (fileName.isNotEmpty && showFileName)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildFileNameText(
              fileName: fileName,
              keyword: highlightKeyword,
            ),
          ),
        if (message.isOutgoing && showOutgoingStatusFooter)
          const SizedBox(height: 4),
        if (message.isOutgoing && showOutgoingStatusFooter)
          GestureDetector(
            onTap:
                enableReadReceiptEntry &&
                    message.status != MessageStatus.sending &&
                    message.status != MessageStatus.failed
                ? () => onOpenReadReceipt?.call(message)
                : null,
            child: Text(
              outgoingFooterLabel ?? _statusLabel(strings),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: _statusColor(theme),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileNameText({
    required String fileName,
    required String? keyword,
  }) {
    if (keyword == null || keyword.isEmpty) {
      return Text(
        fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      );
    }
    final spans = _buildHighlightedSpans(text: fileName, keyword: keyword);
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
    required String text,
    required String keyword,
  }) {
    final spans = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    var lastEnd = 0;
    var startIndex = lowerText.indexOf(lowerKeyword);
    const defaultColor = Color(0xFF6B7280);
    const highlightColor = Color(0xFF246BFD);

    while (startIndex >= 0) {
      if (startIndex > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, startIndex),
            style: const TextStyle(color: defaultColor),
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
          style: const TextStyle(color: defaultColor),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(const TextSpan(text: '', style: TextStyle(color: defaultColor)));
    }
    return spans;
  }

  String _statusLabel(AppLocalizations strings) {
    switch (message.status) {
      case MessageStatus.sending:
        return strings.messageSending;
      case MessageStatus.sent:
        return strings.messageSent;
      case MessageStatus.delivered:
        return strings.messageDelivered;
      case MessageStatus.read:
        return strings.messageRead;
      case MessageStatus.recalled:
        return strings.chatPreviewRecalled;
      case MessageStatus.failed:
        return strings.messageFailed;
    }
  }

  Color _statusColor(ThemeData theme) {
    if (outgoingFooterLabel != null) {
      return const Color(0xFF98A1B2);
    }
    return switch (message.status) {
      MessageStatus.failed => theme.colorScheme.error,
      MessageStatus.read => theme.colorScheme.primary,
      MessageStatus.recalled => const Color(0xFF98A1B2),
      _ => const Color(0xFF98A1B2),
    };
  }

  ImageProvider? _resolveVideoPreviewImageProvider() {
    final thumbnailUrl = message.extra.thumbnailUrl?.trim() ?? '';
    if (thumbnailUrl.isEmpty) {
      return null;
    }
    final videoUrl = _resolveVideoSourceUrl();
    if (videoUrl.isNotEmpty && thumbnailUrl == videoUrl) {
      return null;
    }
    return resolveChatImageProvider(remoteUrl: thumbnailUrl);
  }

  String _resolveVideoSourceUrl() {
    final localPath = message.extra.localPath?.trim() ?? '';
    if (localPath.isNotEmpty) {
      return localPath;
    }
    final fileUrl = message.extra.fileUrl?.trim() ?? '';
    if (fileUrl.isNotEmpty) {
      return fileUrl;
    }
    return extractMediaUrlFromRawContent(message.content);
  }
}

class _OutgoingStatusRow extends StatelessWidget {
  const _OutgoingStatusRow({
    required this.message,
    required this.onRetryMessage,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.status == MessageStatus.sending)
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF98A1B2),
              ),
            ),
          ),
        if (message.status == MessageStatus.failed)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRetryMessage(message),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: AppIcon(
                AppIconKind.error,
                size: 14,
                color: Color(0xFFF54A45),
              ),
            ),
          ),
      ],
    );
  }
}
