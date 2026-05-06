import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';

class ChatComposerController {
  ChatComposerController()
    : textController = EmojiComposerTextEditingController();

  final EmojiComposerTextEditingController textController;
  final List<TextInputFormatter> inputFormatters = <TextInputFormatter>[
    const _EmojiTokenInputFormatter(),
  ];

  String get draft => textController.text;

  void clear() {
    textController.clear();
  }

  void dispose() {
    textController.dispose();
  }
}

class EmojiComposerTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in ChatEmojiCatalog.tokenRegExp.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: style),
        );
      }
      final token = match.group(0) ?? '';
      final assets = ChatEmojiCatalog.candidateAssetsFor(token);
      if (assets.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _ComposerEmojiImage(assets: assets),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: style));
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return TextSpan(style: style, children: spans);
  }
}

class _ComposerEmojiImage extends StatefulWidget {
  const _ComposerEmojiImage({required this.assets});

  final List<String> assets;

  @override
  State<_ComposerEmojiImage> createState() => _ComposerEmojiImageState();
}

class _ComposerEmojiImageState extends State<_ComposerEmojiImage> {
  int _assetIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) {
      return const SizedBox(width: 22, height: 22);
    }
    return Image.asset(
      widget.assets[_assetIndex],
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (_assetIndex + 1 >= widget.assets.length) {
          return const SizedBox(width: 22, height: 22);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _assetIndex++;
          });
        });
        return const SizedBox(width: 22, height: 22);
      },
    );
  }
}

class _EmojiTokenInputFormatter extends TextInputFormatter {
  const _EmojiTokenInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == newValue.text ||
        newValue.text.length >= oldValue.text.length) {
      return newValue;
    }
    final overlap = _findTokenOverlap(oldValue.text, newValue.text);
    if (overlap == null) {
      return newValue;
    }
    final nextText =
        oldValue.text.substring(0, overlap.start) +
        oldValue.text.substring(overlap.end);
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: overlap.start),
    );
  }

  _TokenRange? _findTokenOverlap(String oldText, String newText) {
    final prefixLength = _commonPrefixLength(oldText, newText);
    final suffixLength = _commonSuffixLength(
      oldText.substring(prefixLength),
      newText.substring(prefixLength),
    );
    final removedStart = prefixLength;
    final removedEnd = oldText.length - suffixLength;
    if (removedEnd <= removedStart) {
      return null;
    }
    var expandedStart = removedStart;
    var expandedEnd = removedEnd;
    var matched = false;
    for (final match in ChatEmojiCatalog.tokenRegExp.allMatches(oldText)) {
      if (match.end <= removedStart || match.start >= removedEnd) {
        continue;
      }
      matched = true;
      if (match.start < expandedStart) {
        expandedStart = match.start;
      }
      if (match.end > expandedEnd) {
        expandedEnd = match.end;
      }
    }
    return matched ? _TokenRange(expandedStart, expandedEnd) : null;
  }

  int _commonPrefixLength(String a, String b) {
    final limit = a.length < b.length ? a.length : b.length;
    var index = 0;
    while (index < limit && a.codeUnitAt(index) == b.codeUnitAt(index)) {
      index++;
    }
    return index;
  }

  int _commonSuffixLength(String a, String b) {
    final limit = a.length < b.length ? a.length : b.length;
    var index = 0;
    while (index < limit &&
        a.codeUnitAt(a.length - 1 - index) ==
            b.codeUnitAt(b.length - 1 - index)) {
      index++;
    }
    return index;
  }
}

class _TokenRange {
  const _TokenRange(this.start, this.end);

  final int start;
  final int end;
}
