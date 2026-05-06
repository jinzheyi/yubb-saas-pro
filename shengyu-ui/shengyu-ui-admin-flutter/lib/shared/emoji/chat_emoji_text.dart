import 'package:flutter/material.dart';

import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';

String normalizeEmojiDisplayText(String raw) {
  if (raw.isEmpty) {
    return raw;
  }
  var normalized = raw.replaceAll('\r\n', '\n');
  normalized = normalized.replaceAllMapped(
    RegExp(
      '<img [^>]*alt=["\\\']([^"\\\']+)["\\\'][^>]*>',
      caseSensitive: false,
    ),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(
      r'((?:/static|assets)/images/emoji/[^/\s]+/[^/\s]+?\.png)',
      caseSensitive: false,
    ),
    (match) {
      final token = ChatEmojiCatalog.tokenForAssetLikePath(
        match.group(1) ?? '',
      );
      return token ?? (match.group(1) ?? '');
    },
  );
  normalized = normalized.replaceAll(RegExp(r'<[^>]+>'), '');
  return normalized;
}

List<InlineSpan> buildEmojiInlineSpans({
  required String text,
  required TextStyle textStyle,
  double emojiSize = 20,
  EdgeInsets emojiPadding = const EdgeInsets.symmetric(horizontal: 1.5),
}) {
  if (text.isEmpty) {
    return const <InlineSpan>[TextSpan(text: '')];
  }
  final normalized = normalizeEmojiDisplayText(text);
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in ChatEmojiCatalog.tokenRegExp.allMatches(normalized)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(
          text: normalized.substring(cursor, match.start),
          style: textStyle,
        ),
      );
    }
    final token = match.group(0) ?? '';
    final assets = ChatEmojiCatalog.candidateAssetsFor(token);
    if (assets.isNotEmpty) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: emojiPadding,
            child: ChatEmojiAssetImage(assets: assets, size: emojiSize),
          ),
        ),
      );
    } else {
      spans.add(TextSpan(text: token, style: textStyle));
    }
    cursor = match.end;
  }
  if (cursor < normalized.length) {
    spans.add(TextSpan(text: normalized.substring(cursor), style: textStyle));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: normalized, style: textStyle));
  }
  return spans;
}

class ChatEmojiAssetImage extends StatefulWidget {
  const ChatEmojiAssetImage({
    super.key,
    required this.assets,
    required this.size,
    this.empty = const SizedBox(),
  });

  final List<String> assets;
  final double size;
  final Widget empty;

  @override
  State<ChatEmojiAssetImage> createState() => _ChatEmojiAssetImageState();
}

class _ChatEmojiAssetImageState extends State<ChatEmojiAssetImage> {
  int _assetIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.empty,
      );
    }
    return Image.asset(
      widget.assets[_assetIndex],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        if (_assetIndex + 1 >= widget.assets.length) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: widget.empty,
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _assetIndex++;
          });
        });
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: widget.empty,
        );
      },
    );
  }
}
