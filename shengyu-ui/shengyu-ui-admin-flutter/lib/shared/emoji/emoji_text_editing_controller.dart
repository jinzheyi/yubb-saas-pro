import 'package:flutter/material.dart';

import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_text.dart';

/// 支持 emoji 图文混排的 TextEditingController
/// 使用 Flutter 官方 WidgetSpan 实现，不依赖第三方库
class EmojiTextEditingController extends TextEditingController {
  EmojiTextEditingController({
    String? text,
    this.emojiSize = 18,
    this.emojiPadding = const EdgeInsets.symmetric(horizontal: 0.5),
  }) : super(text: text ?? '');

  final double emojiSize;
  final EdgeInsets emojiPadding;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: buildEmojiInlineSpans(
        text: value.text,
        textStyle: style ?? const TextStyle(),
        emojiSize: emojiSize,
        emojiPadding: emojiPadding,
      ),
    );
  }
}
