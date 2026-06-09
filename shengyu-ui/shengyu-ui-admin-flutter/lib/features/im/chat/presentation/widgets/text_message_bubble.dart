import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class QuotePreviewEntry {
  const QuotePreviewEntry({
    required this.messageId,
    required this.senderName,
    required this.preview,
    required this.missing,
  });

  final String messageId;
  final String senderName;
  final String preview;
  final bool missing;
}

class TextMessageBubble extends ConsumerWidget {
  const TextMessageBubble({
    super.key,
    required this.message,
    required this.onRetryMessage,
    this.quotePreviewChain = const <QuotePreviewEntry>[],
    this.onOpenMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.onOpenMentionUser,
    this.onOpenQuotedMessage,
    this.onOpenLink,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final List<QuotePreviewEntry> quotePreviewChain;
  final ValueChanged<Message>? onOpenMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
  final ValueChanged<String>? onOpenLink;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final bubbleColor = message.isOutgoing
        ? const Color(0xFFD2E3FC)
        : ThemeColors.chatBubbleIncoming(context);
    final textColor = message.isOutgoing
        ? const Color(0xFF1F2329)
        : ThemeColors.chatBubbleIncomingText(context);

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
            onTap: onOpenMessage == null ? null : () => onOpenMessage!(message),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 276),
              decoration: BoxDecoration(
                color: bubbleColor,
                border: message.isOutgoing
                    ? null
                    : Border.all(color: ThemeColors.divider(context)),
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
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(message.isOutgoing ? 12 : 5),
                  bottomRight: Radius.circular(message.isOutgoing ? 5 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: message.isOutgoing
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.quoteInfo != null) ...[
                    _QuotePreviewCard(
                      quoteInfo: message.quoteInfo!,
                      entries: quotePreviewChain,
                      isOutgoing: message.isOutgoing,
                      onTap: message.quoteInfo!.messageId.trim().isEmpty
                          ? null
                          : () => onOpenQuotedMessage?.call(
                              message.quoteInfo!.messageId,
                            ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: textColor,
                      ),
                      children: _buildContentSpans(
                        message: message,
                        defaultColor: textColor,
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

  List<InlineSpan> _buildContentSpans({
    required Message message,
    required Color defaultColor,
  }) {
    final spans = <InlineSpan>[];
    final content = normalizeEmojiDisplayText(message.content);
    if (content.isEmpty) {
      return const <InlineSpan>[TextSpan(text: '')];
    }
    final linkRanges = _extractLinkRanges(content);
    final mentionRanges = message.extra.mentions.isNotEmpty
        ? message.extra.mentions
              .where(
                (item) =>
                    item.startIndex >= 0 &&
                    item.endIndex > item.startIndex &&
                    item.endIndex <= content.length,
              )
              .map(
                (item) => _MentionRange(
                  startIndex: item.startIndex,
                  endIndex: item.endIndex,
                  userId: item.userId,
                ),
              )
              .toList(growable: false)
        : _parseMentions(content);
    if (mentionRanges.isEmpty && linkRanges.isEmpty) {
      return buildEmojiInlineSpans(
        text: content,
        textStyle: TextStyle(color: defaultColor),
      );
    }
    final combinedRanges = <_TextRange>[];
    combinedRanges.addAll(mentionRanges);
    combinedRanges.addAll(linkRanges);
    combinedRanges.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    var cursor = 0;
    for (final range in combinedRanges) {
      if (range.startIndex > cursor) {
        final textBefore = content.substring(cursor, range.startIndex);
        spans.addAll(
          buildEmojiInlineSpans(
            text: textBefore,
            textStyle: TextStyle(color: defaultColor),
          ),
        );
        cursor = range.startIndex;
      }
      if (range is _MentionRange) {
        final mentionText = content.substring(range.startIndex, range.endIndex);
        spans.add(
          TextSpan(
            text: mentionText,
            style: TextStyle(
              color: message.isOutgoing
                  ? const Color(0xFFE4EDFF)
                  : const Color(0xFF246BFD),
              fontWeight: FontWeight.w600,
            ),
            recognizer:
                range.userId == null ||
                    range.userId!.isEmpty ||
                    range.userId == '0' ||
                    onOpenMentionUser == null
                ? null
                : (TapGestureRecognizer()
                    ..onTap = () => onOpenMentionUser!(
                      range.userId!,
                      content.substring(range.startIndex + 1, range.endIndex),
                    )),
          ),
        );
        cursor = range.endIndex;
      } else if (range is _LinkRange) {
        final linkText = content.substring(range.startIndex, range.endIndex);
        spans.add(
          TextSpan(
            text: linkText,
            style: TextStyle(
              color: const Color(0xFF1677FF),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF1677FF),
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _handleLinkTap(range.url),
          ),
        );
        cursor = range.endIndex;
      }
    }
    if (cursor < content.length) {
      spans.addAll(
        buildEmojiInlineSpans(
          text: content.substring(cursor),
          textStyle: TextStyle(color: defaultColor),
        ),
      );
    }
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(color: defaultColor),
        ),
      );
    }
    return spans;
  }

  List<_LinkRange> _extractLinkRanges(String text) {
    final ranges = <_LinkRange>[];
    final patterns = [
      RegExp(r'''https?://[^\s<>"']+''', caseSensitive: false),
      RegExp(r'''www\.[^\s<>"']+''', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        var url = match.group(0)!;
        if (url.endsWith('.') ||
            url.endsWith(',') ||
            url.endsWith(';') ||
            url.endsWith(':')) {
          url = url.substring(0, url.length - 1);
        }
        final normalizedUrl = url.startsWith('www.') ? 'https://$url' : url;
        ranges.add(_LinkRange(
          startIndex: match.start,
          endIndex: match.start + url.length,
          url: normalizedUrl,
        ));
      }
    }
    ranges.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    final merged = <_LinkRange>[];
    for (final range in ranges) {
      if (merged.isEmpty || merged.last.endIndex <= range.startIndex) {
        merged.add(range);
      } else if (range.endIndex > merged.last.endIndex) {
        merged.last = _LinkRange(
          startIndex: merged.last.startIndex,
          endIndex: range.endIndex,
          url: range.url,
        );
      }
    }
    return merged;
  }

  void _handleLinkTap(String url) {
    if (onOpenLink != null) {
      onOpenLink!(url);
    }
  }

  List<_MentionRange> _parseMentions(String text) {
    final mentions = <_MentionRange>[];
    var index = 0;
    while (index < text.length) {
      if (text[index] != '@') {
        index++;
        continue;
      }
      final nextIndex = index + 1;
      if (nextIndex >= text.length) {
        index++;
        continue;
      }
      final nextChar = text[nextIndex];
      if (_isBoundary(nextChar) || nextChar == '@') {
        index++;
        continue;
      }
      var endIndex = nextIndex;
      while (endIndex < text.length) {
        final char = text[endIndex];
        if (_isBoundary(char) || char == '@') {
          break;
        }
        endIndex++;
      }
      if (endIndex > nextIndex) {
        mentions.add(_MentionRange(startIndex: index, endIndex: endIndex));
        index = endIndex;
        continue;
      }
      index++;
    }
    return mentions;
  }

  bool _isBoundary(String value) =>
      value == ' ' || value == '\t' || value == '\n' || value == '\r';
}

class _MentionRange extends _TextRange {
  const _MentionRange({
    required super.startIndex,
    required super.endIndex,
    this.userId,
  });

  final String? userId;
}

class _LinkRange extends _TextRange {
  const _LinkRange({
    required super.startIndex,
    required super.endIndex,
    required this.url,
  });

  final String url;
}

abstract class _TextRange {
  const _TextRange({
    required this.startIndex,
    required this.endIndex,
  });

  final int startIndex;
  final int endIndex;
}

class _QuotePreviewCard extends StatelessWidget {
  const _QuotePreviewCard({
    required this.quoteInfo,
    required this.entries,
    required this.isOutgoing,
    this.onTap,
  });

  final QuoteInfo quoteInfo;
  final List<QuotePreviewEntry> entries;
  final bool isOutgoing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = isOutgoing
        ? const Color(0xFFE4EDFF)
        : const Color(0xFF246BFD);
    final contentColor = isOutgoing
        ? const Color(0xFFD7E3FF)
        : const Color(0xFF6B7380);
    final strings = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 236),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: isOutgoing
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0x0D000000),
          borderRadius: BorderRadius.circular(4),
          border: const Border(
            left: BorderSide(color: Color(0xFF1677FF), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entries.isEmpty) ...[
              Text(
                quoteInfo.senderName.trim().isNotEmpty
                    ? quoteInfo.senderName
                    : strings.chatPreviewUnknownSender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quoteInfo.preview.trim().isNotEmpty
                    ? quoteInfo.preview
                    : strings.chatPreviewMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: contentColor,
                ),
              ),
            ] else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                _QuoteChainItem(
                  entry: entries[i],
                  isOutgoing: isOutgoing,
                  isNested: i > 0,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _QuoteChainItem extends StatelessWidget {
  const _QuoteChainItem({
    required this.entry,
    required this.isOutgoing,
    required this.isNested,
  });

  final QuotePreviewEntry entry;
  final bool isOutgoing;
  final bool isNested;

  @override
  Widget build(BuildContext context) {
    final titleColor = isOutgoing
        ? const Color(0xFFE4EDFF)
        : const Color(0xFF246BFD);
    final contentColor = isOutgoing
        ? const Color(0xFFD7E3FF)
        : const Color(0xFF6B7380);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: isNested ? 6 : 0),
      decoration: isNested
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isOutgoing
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0x1F000000),
                  width: 1,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: entry.missing
                  ? contentColor.withValues(alpha: 0.82)
                  : contentColor,
            ),
          ),
        ],
      ),
    );
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
