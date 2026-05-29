import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class FileMessageBubble extends ConsumerWidget {
  const FileMessageBubble({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final bubbleColor = message.isOutgoing
        ? const Color(0xFF2F6BFF)
        : Colors.white;
    final displayName = _displayName(strings);
    final fileIconSpec = _resolveFileIconSpec();

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
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                border: message.isOutgoing
                    ? null
                    : Border.all(color: const Color(0xFFEFF2F6)),
                boxShadow: message.isOutgoing
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0A162033),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(message.isOutgoing ? 10 : 5),
                  bottomRight: Radius.circular(message.isOutgoing ? 5 : 10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFileNameText(
                          displayName: displayName,
                          isOutgoing: message.isOutgoing,
                          keyword: highlightKeyword,
                        ),
                        if (message.extra.fileSize != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(message.extra.fileSize!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: message.isOutgoing
                                  ? const Color(0xFFDDE6FF)
                                  : const Color(0xFF98A1B2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        fileIconSpec.icon,
                        size: 44,
                        color: fileIconSpec.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildFileNameText({
    required String displayName,
    required bool isOutgoing,
    required String? keyword,
  }) {
    if (keyword == null || keyword.isEmpty) {
      return Text(
        displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isOutgoing ? Colors.white : const Color(0xFF202531),
        ),
      );
    }
    final spans = _buildHighlightedSpans(
      text: displayName,
      keyword: keyword,
      defaultColor: isOutgoing ? Colors.white : const Color(0xFF202531),
      isOutgoing: isOutgoing,
    );
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedSpans({
    required String text,
    required String keyword,
    required Color defaultColor,
    required bool isOutgoing,
  }) {
    final spans = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    var lastEnd = 0;
    var startIndex = lowerText.indexOf(lowerKeyword);

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
          style: TextStyle(
            color: isOutgoing ? const Color(0xFFFFD700) : const Color(0xFF246BFD),
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
      spans.add(TextSpan(text: text, style: TextStyle(color: defaultColor)));
    }
    return spans;
  }

  String _displayName(AppLocalizations strings) {
    final fileName = message.extra.fileName?.trim() ?? '';
    if (fileName.isNotEmpty) {
      return fileName;
    }
    final rawUrl = extractMediaUrlFromRawContent(
      message.content,
      fallbackMixedContent: true,
    );
    final pathName = basenameFromUrlOrPath(rawUrl);
    if (pathName.isNotEmpty) {
      return pathName;
    }
    final content = message.content.trim();
    if (content.isNotEmpty && !content.startsWith('{')) {
      return content;
    }
    return strings.chatMediaFileFallback;
  }

  _ChatFileIconSpec _resolveFileIconSpec() {
    final fileName = message.extra.fileName?.trim() ?? '';
    final mimeType = _fileMimeType;
    final extension = _fileExtension(fileName);

    if (mimeType.isNotEmpty) {
      if (mimeType.contains('ms-excel') || mimeType.contains('spreadsheetml')) {
        return const _ChatFileIconSpec(
          icon: ShengyuIconFont.fileSpreadsheet,
          color: Color(0xFF34C759),
        );
      }
      if (mimeType.contains('msword') ||
          mimeType.contains('wordprocessingml')) {
        return const _ChatFileIconSpec(
          icon: ShengyuIconFont.fileWord,
          color: Color(0xFF3370FF),
        );
      }
      if (mimeType.contains('ms-powerpoint') ||
          mimeType.contains('presentationml')) {
        return const _ChatFileIconSpec(
          icon: ShengyuIconFont.filePresentation,
          color: Color(0xFFFF9500),
        );
      }
      if (mimeType == 'application/pdf') {
        return const _ChatFileIconSpec(
          icon: ShengyuIconFont.filePdf,
          color: Color(0xFFF54A45),
        );
      }
    }

    if (mimeType.startsWith('image/') || _isImageExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileImage,
        color: Color(0xFFFFB020),
      );
    }
    if (mimeType.startsWith('video/') || _isVideoExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileVideo,
        color: Color(0xFF8A5CF6),
      );
    }
    if (mimeType.startsWith('audio/') || _isAudioExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileAudio,
        color: Color(0xFFFF9500),
      );
    }
    if (extension == 'html' || extension == 'htm') {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileHtml,
        color: Color(0xFFFF6A00),
      );
    }
    if (extension == 'sql') {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.wenjianleixing,
        color: Color(0xFF8F959E),
      );
    }
    if (extension == 'pdf') {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.filePdf,
        color: Color(0xFFF54A45),
      );
    }
    if (_isWordExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileWord,
        color: Color(0xFF3370FF),
      );
    }
    if (_isExcelExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileSpreadsheet,
        color: Color(0xFF34C759),
      );
    }
    if (_isPptExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.filePresentation,
        color: Color(0xFFFF9500),
      );
    }
    if (_isZipExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.fileZip,
        color: Color(0xFF586C76),
      );
    }
    if (_isTextExtension(extension)) {
      return const _ChatFileIconSpec(
        icon: ShengyuIconFont.zhuyaolunwenzhuzuo,
        color: Color(0xFF4A90E2),
      );
    }
    return const _ChatFileIconSpec(
      icon: ShengyuIconFont.wentigenzong,
      color: Color(0xFFC7CBD1),
    );
  }

  String get _fileMimeType {
    final primary = message.extra.mimeType?.trim().toLowerCase() ?? '';
    if (primary.isNotEmpty) {
      return primary;
    }
    return message.extra.fileType?.trim().toLowerCase() ?? '';
  }

  String _fileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot < 0 || lastDot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  bool _isImageExtension(String ext) => const <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'svg',
    'heic',
  ].contains(ext);

  bool _isVideoExtension(String ext) => const <String>[
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
    '3gp',
    'flv',
  ].contains(ext);

  bool _isAudioExtension(String ext) => const <String>[
    'mp3',
    'wav',
    'aac',
    'm4a',
    'ogg',
    'flac',
    'amr',
  ].contains(ext);

  bool _isZipExtension(String ext) => const <String>[
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'xz',
  ].contains(ext);

  bool _isWordExtension(String ext) =>
      const <String>['doc', 'docx', 'dot', 'dotx'].contains(ext);

  bool _isExcelExtension(String ext) =>
      const <String>['xls', 'xlsx', 'csv'].contains(ext);

  bool _isPptExtension(String ext) =>
      const <String>['ppt', 'pptx', 'pps', 'ppsx'].contains(ext);

  bool _isTextExtension(String ext) => const <String>[
    'txt',
    'log',
    'md',
    'json',
    'xml',
    'yml',
    'yaml',
    'ini',
    'conf',
  ].contains(ext);
}

class _ChatFileIconSpec {
  const _ChatFileIconSpec({required this.icon, required this.color});

  final IconData icon;
  final Color color;
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
