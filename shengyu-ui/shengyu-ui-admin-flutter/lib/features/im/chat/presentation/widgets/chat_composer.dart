import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_composer_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_special_text_span_builder.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.composer,
    required this.onSend,
    required this.isSending,
    required this.hintText,
    required this.onOpenAttachmentMenu,
    required this.onTapInput,
    required this.onTapVoice,
    required this.voiceMode,
    required this.isRecording,
    required this.isCancelReady,
    required this.onVoicePressStart,
    required this.onVoicePressMove,
    required this.onVoicePressEnd,
    required this.onVoicePressCancel,
    required this.onTapEmoji,
    required this.focusNode,
    this.onChanged,
    this.fullExpanded = false,
    this.showExpandAction = false,
    this.composerHeight = 40,
    this.onToggleExpand,
    this.quoteInfo,
    this.onClearQuote,
  });

  final ChatComposerController composer;
  final ValueChanged<String> onSend;
  final bool isSending;
  final String hintText;
  final VoidCallback onOpenAttachmentMenu;
  final VoidCallback onTapInput;
  final VoidCallback onTapVoice;
  final bool voiceMode;
  final bool isRecording;
  final bool isCancelReady;
  final void Function(Offset globalPosition) onVoicePressStart;
  final void Function(Offset globalPosition) onVoicePressMove;
  final VoidCallback onVoicePressEnd;
  final VoidCallback onVoicePressCancel;
  final VoidCallback onTapEmoji;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final bool fullExpanded;
  final bool showExpandAction;
  final double composerHeight;
  final VoidCallback? onToggleExpand;
  final QuoteInfo? quoteInfo;
  final VoidCallback? onClearQuote;

  static const StrutStyle _composerStrutStyle = StrutStyle(
    fontSize: 15,
    height: 22 / 15,
    leading: 0,
    forceStrutHeight: true,
  );
  @override
  Widget build(BuildContext context) {
    final controller = composer.textController;
    final fullExpandedEmojiBuilder = ChatEmojiSpecialTextSpanBuilder(
      fontSize: 16,
      emojiSize: 20,
      horizontalMargin: 0.5,
    );
    final composerEmojiBuilder = ChatEmojiSpecialTextSpanBuilder(
      fontSize: 15,
      emojiSize: 18,
      horizontalMargin: 0.5,
    );
    final composerFillColor = ThemeColors.inputFill(context);
    final composerBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: ThemeColors.divider(context), width: 1),
    );
    final composerHintStyle = TextStyle(
      color: ThemeColors.searchHint(context),
      fontSize: 15,
      height: 22 / 15,
    );
    final composerInputStyle = TextStyle(
      fontSize: 15,
      height: 22 / 15,
      color: ThemeColors.textPrimary(context),
    );
    final fullExpandedInputStyle = TextStyle(
      fontSize: 16,
      height: 24 / 16,
      color: ThemeColors.textPrimary(context),
    );
    if (fullExpanded) {
      return SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 44,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: ThemeColors.divider(context), width: 0.5),
                  ),
                ),
                child: GestureDetector(
                  onTap: onToggleExpand,
                  child: AppIcon(
                    AppIconKind.expandMore,
                    size: 24,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
              if (quoteInfo != null)
                _QuoteReplyBar(quoteInfo: quoteInfo!, onClear: onClearQuote),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ExtendedTextField(
                          controller: controller,
                          focusNode: focusNode,
                          specialTextSpanBuilder: fullExpandedEmojiBuilder,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          strutStyle: const StrutStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            leading: 0,
                            forceStrutHeight: true,
                          ),
                          onTap: onTapInput,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: composerFillColor,
                            hintText: '',
                            contentPadding: const EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              12,
                            ),
                            enabledBorder: composerBorder,
                            focusedBorder: composerBorder,
                            border: composerBorder,
                            hintStyle: composerHintStyle,
                          ).copyWith(hintText: hintText),
                          style: fullExpandedInputStyle,
                          inputFormatters: composer.inputFormatters,
                          onChanged: onChanged,
                        ),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _PlainToolButton(
                              icon: AppIconKind.smile,
                              onTap: isSending ? null : onTapEmoji,
                            ),
                            const SizedBox(width: 10),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: controller,
                              builder: (context, value, child) {
                                final canSend =
                                    value.text.trim().isNotEmpty && !isSending;
                                if (!canSend) {
                                  return _PlainToolButton(
                                    icon: AppIconKind.add,
                                    onTap: isSending
                                        ? null
                                        : onOpenAttachmentMenu,
                                  );
                                }
                                return SizedBox(
                                  height: 32,
                                  child: FilledButton(
                                    onPressed: () => onSend(value.text),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF07C160),
                                      minimumSize: const Size(56, 32),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: isSending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            AppLocalizations.of(
                                              context,
                                            ).chatForwardDialogSend,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.surface(context),
          border: Border(top: BorderSide(color: ThemeColors.divider(context), width: 1)),
        ),
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quoteInfo != null) ...[
              _QuoteReplyBar(quoteInfo: quoteInfo!, onClear: onClearQuote),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PlainToolButton(
                    icon: voiceMode ? AppIconKind.keyboard : AppIconKind.mic,
                    onTap: isSending ? null : onTapVoice,
                  ),
                  if (showExpandAction) ...[
                    const SizedBox(width: 8),
                    _PlainToolButton(
                      icon: AppIconKind.openInFull,
                      onTap: isSending ? null : onToggleExpand,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: voiceMode
                        ? _HoldToTalkButton(
                            enabled: !isSending,
                            isRecording: isRecording,
                            isCancelReady: isCancelReady,
                            onPressStart: onVoicePressStart,
                            onPressMove: onVoicePressMove,
                            onPressEnd: onVoicePressEnd,
                            onPressCancel: onVoicePressCancel,
                          )
                        : SizedBox(
                            height: composerHeight,
                            child: ExtendedTextField(
                              controller: controller,
                              focusNode: focusNode,
                              specialTextSpanBuilder: composerEmojiBuilder,
                              minLines: 1,
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              textAlignVertical: TextAlignVertical.top,
                              strutStyle: _composerStrutStyle,
                              onTap: onTapInput,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: composerFillColor,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  8,
                                ),
                                enabledBorder: composerBorder,
                                focusedBorder: composerBorder,
                                border: composerBorder,
                                hintStyle: composerHintStyle,
                              ).copyWith(hintText: hintText),
                              style: composerInputStyle,
                              inputFormatters: composer.inputFormatters,
                              onChanged: onChanged,
                              onSubmitted: isSending ? null : onSend,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  _PlainToolButton(
                    icon: AppIconKind.smile,
                    onTap: isSending ? null : onTapEmoji,
                  ),
                  const SizedBox(width: 8),
                  if (!voiceMode)
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, child) {
                        final canSend =
                            value.text.trim().isNotEmpty && !isSending;
                        if (!canSend) {
                          return _PlainToolButton(
                            icon: AppIconKind.add,
                            onTap: isSending ? null : onOpenAttachmentMenu,
                          );
                        }
                        return SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: () => onSend(value.text),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF07C160),
                              minimumSize: const Size(56, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      context,
                                    ).chatForwardDialogSend,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldToTalkButton extends StatelessWidget {
  const _HoldToTalkButton({
    required this.enabled,
    required this.isRecording,
    required this.isCancelReady,
    required this.onPressStart,
    required this.onPressMove,
    required this.onPressEnd,
    required this.onPressCancel,
  });

  final bool enabled;
  final bool isRecording;
  final bool isCancelReady;
  final void Function(Offset globalPosition) onPressStart;
  final void Function(Offset globalPosition) onPressMove;
  final VoidCallback onPressEnd;
  final VoidCallback onPressCancel;

  @override
  Widget build(BuildContext context) {
    final label = isRecording ? (isCancelReady ? '松开取消' : '松开发送') : '按住说话';
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled ? (event) => onPressStart(event.position) : null,
      onPointerMove: enabled ? (event) => onPressMove(event.position) : null,
      onPointerUp: enabled ? (_) => onPressEnd() : null,
      onPointerCancel: enabled ? (_) => onPressCancel() : null,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isRecording
              ? ThemeColors.textPrimary(context).withValues(alpha: 0.83)
              : ThemeColors.inputFill(context),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCancelReady
                ? ThemeColors.errorText(context).withValues(alpha: 0.8)
                : ThemeColors.divider(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: !enabled
                ? ThemeColors.textSecondary(context)
                : (isRecording ? Colors.white : ThemeColors.textPrimary(context)),
          ),
        ),
      ),
    );
  }
}

class _QuoteReplyBar extends StatelessWidget {
  const _QuoteReplyBar({required this.quoteInfo, this.onClear});

  final QuoteInfo quoteInfo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceDim(context),
        border: Border(
          top: BorderSide(color: ThemeColors.divider(context), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: const Border(
                  left: BorderSide(color: Color(0xFF1677FF), width: 3),
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: 0,
                    child: Text(
                      quoteInfo.senderName.trim().isNotEmpty
                          ? quoteInfo.senderName
                          : strings.chatPreviewUnknownSender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quoteInfo.preview.trim().isNotEmpty
                          ? quoteInfo.preview
                          : strings.chatPreviewMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AppIcon(
                AppIconKind.close,
                size: 20,
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainToolButton extends StatelessWidget {
  const _PlainToolButton({required this.icon, this.onTap});

  final Object icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = onTap == null
        ? ThemeColors.textSecondary(context).withValues(alpha: 0.6)
        : ThemeColors.textPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 30,
        height: 40,
        child: icon is AppIconKind
            ? Center(
                child: AppIcon(icon as AppIconKind, size: 24, color: iconColor),
              )
            : Center(child: Icon(icon as IconData, size: 24, color: iconColor)),
      ),
    );
  }
}
