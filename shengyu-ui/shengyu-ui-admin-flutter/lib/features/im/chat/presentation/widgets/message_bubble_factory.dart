import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/contact_card_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/custom_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/file_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/image_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/location_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/sticker_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/text_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/video_message_bubble.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/voice_message_bubble.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

abstract final class MessageBubbleFactory {
  static Widget build(
    Message message, {
    required ValueChanged<Message> onRetryMessage,
    required ValueChanged<Message> onOpenMessage,
    ValueChanged<Message>? onPauseMessage,
    ValueChanged<Message>? onResumeMessage,
    ValueChanged<Message>? onReplayMessage,
    bool voiceIsPlaying = false,
    bool voiceIsPaused = false,
    int voicePlaybackProgressMs = 0,
    int voicePlaybackDurationMs = 0,
    void Function(Message, Offset globalPosition)? onLongPressMessage,
    ValueChanged<Message>? onOpenReadReceipt,
    void Function(String userId, String displayName)? onOpenMentionUser,
    ValueChanged<String>? onOpenQuotedMessage,
    ValueChanged<String>? onOpenLink,
    List<QuotePreviewEntry> quotePreviewChain = const <QuotePreviewEntry>[],
    bool enableReadReceiptEntry = false,
    bool showOutgoingStatusFooter = true,
    String? outgoingFooterLabel,
    String? highlightKeyword,
    bool showFileName = false,
  }) {
    // Note: Normalization is already applied at MessageDtoMapper.toEntity()
    switch (message.type) {
      case MessageType.text:
        return TextMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          onOpenMentionUser: onOpenMentionUser,
          onOpenQuotedMessage: onOpenQuotedMessage,
          onOpenLink: onOpenLink,
          quotePreviewChain: quotePreviewChain,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.image:
        return ImageMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
          highlightKeyword: highlightKeyword,
          showFileName: showFileName,
        );
      case MessageType.voice:
        return VoiceMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onPauseMessage: onPauseMessage,
          onResumeMessage: onResumeMessage,
          onReplayMessage: onReplayMessage,
          isPlaying: voiceIsPlaying,
          isPaused: voiceIsPaused,
          playbackProgressMs: voicePlaybackProgressMs,
          playbackDurationMs: voicePlaybackDurationMs,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.video:
        return VideoMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
          highlightKeyword: highlightKeyword,
          showFileName: showFileName,
        );
      case MessageType.file:
        return FileMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
          highlightKeyword: highlightKeyword,
        );
      case MessageType.location:
        return LocationMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.contactCard:
        return ContactCardMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.emoji:
      case MessageType.sticker:
        return StickerMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.custom:
        if ((message.extra.customType?.trim().toUpperCase() ?? '') ==
            'CONTACT_CARD') {
          return ContactCardMessageBubble(
            message: message,
            onRetryMessage: onRetryMessage,
            onOpenMessage: onOpenMessage,
            onLongPressMessage: onLongPressMessage,
            onOpenReadReceipt: onOpenReadReceipt,
            enableReadReceiptEntry: enableReadReceiptEntry,
            showOutgoingStatusFooter: showOutgoingStatusFooter,
            outgoingFooterLabel: outgoingFooterLabel,
          );
        }
        return CustomMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
      case MessageType.system:
        return TextMessageBubble(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenMessage: onOpenMessage,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          onOpenQuotedMessage: onOpenQuotedMessage,
          quotePreviewChain: quotePreviewChain,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        );
    }
  }

}
