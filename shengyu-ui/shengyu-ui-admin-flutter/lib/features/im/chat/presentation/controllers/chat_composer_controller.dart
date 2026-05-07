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
  static const double asciiWidthUnit = 0.55;
  static const double commonWidthUnit = 1;
  static const double emojiWidthUnit = 1.55;
  static final RegExp _tokenRegExp = ChatEmojiCatalog.tokenRegExp;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
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
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
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

  void insertToken(String insertedText) {
    if (insertedText.isEmpty) {
      return;
    }
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(0, text.length)
        : text.length;
    final lower = start <= end ? start : end;
    final upper = start <= end ? end : start;
    final nextText =
        text.substring(0, lower) + insertedText + text.substring(upper);
    final nextOffset = lower + insertedText.length;
    value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  void deletePreviousUnit() {
    final text = value.text;
    if (text.isEmpty) {
      return;
    }
    final selection = value.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(0, text.length)
        : text.length;
    final lower = start <= end ? start : end;
    final upper = start <= end ? end : start;
    if (lower != upper) {
      value = TextEditingValue(
        text: text.substring(0, lower) + text.substring(upper),
        selection: TextSelection.collapsed(offset: lower),
      );
      return;
    }
    if (lower <= 0) {
      return;
    }
    final tokenRange = _findTokenCoveringCursor(text, lower);
    if (tokenRange != null) {
      value = TextEditingValue(
        text:
            text.substring(0, tokenRange.start) +
            text.substring(tokenRange.end),
        selection: TextSelection.collapsed(offset: tokenRange.start),
      );
      return;
    }
    value = TextEditingValue(
      text: text.substring(0, lower - 1) + text.substring(lower),
      selection: TextSelection.collapsed(offset: lower - 1),
    );
  }

  static double measureVisualWidthUnits(String text) {
    if (text.isEmpty) {
      return 0;
    }
    var units = 0.0;
    var cursor = 0;
    for (final match in _tokenRegExp.allMatches(text)) {
      if (match.start > cursor) {
        units += _measurePlainTextUnits(text.substring(cursor, match.start));
      }
      final token = match.group(0) ?? '';
      units += ChatEmojiCatalog.assetFor(token) == null
          ? _measurePlainTextUnits(token)
          : emojiWidthUnit;
      cursor = match.end;
    }
    if (cursor < text.length) {
      units += _measurePlainTextUnits(text.substring(cursor));
    }
    return units;
  }

  static double _measurePlainTextUnits(String text) {
    var units = 0.0;
    var index = 0;
    while (index < text.length) {
      final charCode = text.codeUnitAt(index);
      if (charCode <= 0x007f) {
        units += asciiWidthUnit;
        index++;
        continue;
      }
      if (charCode >= 0xd800 && charCode <= 0xdbff && index + 1 < text.length) {
        units += commonWidthUnit;
        index += 2;
        continue;
      }
      units += commonWidthUnit;
      index++;
    }
    return units;
  }

  _TokenRange? _findTokenCoveringCursor(String text, int cursor) {
    for (final match in _tokenRegExp.allMatches(text)) {
      final token = match.group(0) ?? '';
      if (ChatEmojiCatalog.assetFor(token) == null) {
        continue;
      }
      if (cursor > match.start && cursor <= match.end) {
        return _TokenRange(match.start, match.end);
      }
    }
    return null;
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
      return const SizedBox(width: 20, height: 20);
    }
    return Image.asset(
      widget.assets[_assetIndex],
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        if (_assetIndex + 1 >= widget.assets.length) {
          return const SizedBox(width: 20, height: 20);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _assetIndex++;
          });
        });
        return const SizedBox(width: 20, height: 20);
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
