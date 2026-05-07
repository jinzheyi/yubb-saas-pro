import 'dart:ui' as ui;

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';

class ChatEmojiSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  ChatEmojiSpecialTextSpanBuilder({
    this.fontSize = 15,
    this.emojiSize,
    this.horizontalMargin = 0.5,
  });

  final double fontSize;
  final double? emojiSize;
  final double horizontalMargin;

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    if (flag.isEmpty || !isStart(flag, _ChatEmojiSpecialText.flag)) {
      return null;
    }
    return _ChatEmojiSpecialText(
      textStyle,
      start: index - (_ChatEmojiSpecialText.flag.length - 1),
      emojiSize: emojiSize ?? _resolveEmojiSize(textStyle),
      horizontalMargin: horizontalMargin,
    );
  }

  double _resolveEmojiSize(TextStyle? textStyle) {
    final baseFontSize = textStyle?.fontSize ?? fontSize;
    return baseFontSize * 1.18;
  }
}

class _ChatEmojiSpecialText extends SpecialText {
  _ChatEmojiSpecialText(
    TextStyle? textStyle, {
    required this.start,
    required this.emojiSize,
    required this.horizontalMargin,
  }) : super(flag, ']', textStyle);

  static const String flag = '[';

  final int start;
  final double emojiSize;
  final double horizontalMargin;

  @override
  InlineSpan finishText() {
    final token = toString();
    final asset = ChatEmojiCatalog.assetFor(token);
    if (asset == null || asset.isEmpty) {
      return TextSpan(text: token, style: textStyle);
    }
    return ImageSpan(
      AssetImage(asset),
      actualText: token,
      start: start,
      imageWidth: emojiSize,
      imageHeight: emojiSize,
      alignment: ui.PlaceholderAlignment.middle,
      baseline: TextBaseline.alphabetic,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
