import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class CustomMessageBubble extends ConsumerWidget {
  const CustomMessageBubble({
    super.key,
    required this.message,
    required this.onRetryMessage,
    required this.onOpenMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final model = _buildCardModel(strings);

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
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isOutgoing
                    ? const Color(0xFFD2E3FC)
                    : ThemeColors.chatBubbleIncoming(context),
                border: message.isOutgoing
                    ? null
                    : Border.all(color: ThemeColors.divider(context)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(message.isOutgoing ? 10 : 5),
                  bottomRight: Radius.circular(message.isOutgoing ? 5 : 10),
                ),
              ),
              child: model.isForwardCombine
                  ? _ForwardCombineCard(
                      message: message,
                      title: strings.chatForwardCombine,
                      comment: model.comment,
                      lines: model.lines,
                      footer: strings.chatClickToViewDetail,
                    )
                  : Text(
                      model.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: message.isOutgoing
                            ? const Color(0xFF1F2329)
                            : const Color(0xFF202531),
                      ),
                    ),
            ),
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

  _CustomCardModel _buildCardModel(AppLocalizations strings) {
    final body = _decodeMap(message.content);
    if ((message.extra.customType?.toUpperCase() ?? '') == 'FORWARD_COMBINE') {
      final comment = body?['comment']?.toString().trim() ?? '';
      final lines = _buildForwardCombineLines(body, strings);
      return _CustomCardModel(
        title: strings.chatForwardCombine,
        comment: comment,
        lines: lines,
        isForwardCombine: true,
      );
    }
    return _CustomCardModel(title: strings.chatCustomMessage);
  }

  List<String> _buildForwardCombineLines(
    Map<String, dynamic>? body,
    AppLocalizations strings,
  ) {
    final rawItems = body?['messages'];
    if (rawItems is! List) {
      return const <String>[];
    }
    final lines = <String>[];
    for (final item in rawItems.take(3)) {
      if (item is! Map) {
        continue;
      }
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final senderName = map['senderName']?.toString().trim() ?? '';
      final preview = _forwardCombinePreviewForItem(map, strings);
      if (senderName.isNotEmpty) {
        lines.add('$senderName：$preview');
      } else {
        lines.add(preview);
      }
    }
    return lines;
  }

  String _forwardCombinePreviewForItem(
    Map<String, dynamic> item,
    AppLocalizations strings,
  ) {
    final messageType = item['messageType'] is num
        ? (item['messageType'] as num).toInt()
        : int.tryParse(item['messageType']?.toString() ?? '') ?? 0;
    if (messageType == 1 || messageType == 100 || messageType == 205) {
      final parsed = _decodeMap(item['content']);
      final replyContent = parsed?['replyContent']?.toString().trim() ?? '';
      if (replyContent.isNotEmpty) {
        return replyContent;
      }
      final content = parsed?['content']?.toString().trim() ?? '';
      if (content.isNotEmpty) {
        return content;
      }
      final raw = item['content']?.toString().trim() ?? '';
      return raw.isNotEmpty ? raw : strings.chatPreviewMessage;
    }
    if (messageType == 9 || messageType == 106) {
      final body = _decodeMap(item['content']);
      final type = body?['type']?.toString() ?? '';
      if (type == 'FORWARD_COMBINE') {
        return strings.chatForwardCombine;
      }
      if (type == 'STICKER') {
        return strings.chatPreviewSticker;
      }
      if (type == 'CONTACT_CARD') {
        return strings.chatPreviewContactCard;
      }
      return strings.chatPreviewMessage;
    }
    return switch (messageType) {
      2 || 101 => strings.chatPreviewImage,
      3 || 102 => strings.chatPreviewVoice,
      4 || 103 => strings.chatPreviewVideo,
      5 || 104 => strings.chatPreviewFile,
      6 || 105 => strings.chatPreviewLocation,
      7 => strings.chatPreviewEmoji,
      8 => strings.chatPreviewSticker,
      _ => strings.chatPreviewMessage,
    };
  }

  Map<String, dynamic>? _decodeMap(Object? raw) {
    try {
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      if (raw is! String) {
        return null;
      }
      final trimmed = raw.trim();
      if (trimmed.isEmpty ||
          ((!trimmed.startsWith('{') || !trimmed.endsWith('}')) &&
              (!trimmed.startsWith('[') || !trimmed.endsWith(']')))) {
        return null;
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      debugPrint('[CustomBubble] jsonDecode failed: $e');
    }
    return null;
  }
}

class _CustomCardModel {
  const _CustomCardModel({
    required this.title,
    this.comment = '',
    this.lines = const <String>[],
    this.isForwardCombine = false,
  });

  final String title;
  final String comment;
  final List<String> lines;
  final bool isForwardCombine;
}

class _ForwardCombineCard extends StatelessWidget {
  const _ForwardCombineCard({
    required this.message,
    required this.title,
    required this.comment,
    required this.lines,
    required this.footer,
  });

  final Message message;
  final String title;
  final String comment;
  final List<String> lines;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isOutgoing;
    final titleColor = isOutgoing ? Colors.white : ThemeColors.textPrimary(context);
    final secondaryColor = isOutgoing
        ? const Color(0xFFD7E3FF)
        : ThemeColors.textSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(AppIconKind.topic, size: 18, color: titleColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            comment,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
        ],
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            height: 0.5,
            color: isOutgoing
                ? const Color(0x6697B9F3)
                : const Color(0xFFE5E6EB),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                Text(
                  lines[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 0.5,
          color: isOutgoing
              ? const Color(0x6697B9F3)
              : const Color(0xFFE5E6EB),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ),
            AppIcon(
              AppIconKind.chevronRight,
              size: 14,
              color: secondaryColor,
            ),
          ],
        ),
      ],
    );
  }
}
