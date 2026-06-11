import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/core/i18n/system_message_renderer.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_avatar.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_bubble_factory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/text_message_bubble.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatTimeline extends StatelessWidget {
  const ChatTimeline({
    super.key,
    required this.messages,
    this.messageItemKeys = const <String, GlobalKey>{},
    this.controller,
    required this.onRetryMessage,
    required this.onOpenMessage,
    this.onPauseVoiceMessage,
    this.onResumeVoiceMessage,
    this.onReplayVoiceMessage,
    this.onOpenMentionUser,
    this.onOpenQuotedMessage,
    this.onOpenLink,
    this.onReeditRecalledMessage,
    required this.reeditNowTs,
    this.onOpenReadReceipt,
    this.highlightedMessageId,
    this.selectionMode = false,
    this.selectedMessageIds = const <String>{},
    this.onToggleSelection,
    this.onLongPressMessage,
    this.onLoadOlder,
    this.isLoadingOlder = false,
    this.activePlayingVoiceMessageId,
    this.activePausedVoiceMessageId,
    this.activeVoicePlaybackProgressMs = 0,
    this.activeVoicePlaybackDurationMs = 0,
    this.outgoingFooterLabelBuilder,
    this.showSenderNamesForIncoming = false,
    this.watermarkText,
  });

  final List<Message> messages;
  final Map<String, GlobalKey> messageItemKeys;
  final ScrollController? controller;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final ValueChanged<Message>? onPauseVoiceMessage;
  final ValueChanged<Message>? onResumeVoiceMessage;
  final ValueChanged<Message>? onReplayVoiceMessage;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
  final ValueChanged<String>? onOpenLink;
  final ValueChanged<Message>? onReeditRecalledMessage;
  final int reeditNowTs;
  final ValueChanged<Message>? onOpenReadReceipt;
  final String? highlightedMessageId;
  final bool selectionMode;
  final Set<String> selectedMessageIds;
  final ValueChanged<Message>? onToggleSelection;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final Future<void> Function()? onLoadOlder;
  final bool isLoadingOlder;
  final String? activePlayingVoiceMessageId;
  final String? activePausedVoiceMessageId;
  final int activeVoicePlaybackProgressMs;
  final int activeVoicePlaybackDurationMs;
  final String Function(Message message)? outgoingFooterLabelBuilder;
  final bool showSenderNamesForIncoming;
  final String? watermarkText;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    // 构建消息 ID → Message 的哈希索引表，供引用链查找使用 O(1)
    final messageIndex = <String, Message>{};
    for (final msg in messages) {
      if (msg.messageId.isNotEmpty) {
        messageIndex[msg.messageId] = msg;
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: _ChatWatermarkLayer(text: watermarkText ?? '')),
        RefreshIndicator(
          onRefresh: () async {
            await onLoadOlder?.call();
          },
          child: ListView.builder(
            controller: controller,
            // ignore: deprecated_member_use
            cacheExtent: 500.0,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _LoadOlderBar(
                  isLoading: isLoadingOlder,
                  onTap: onLoadOlder == null
                      ? null
                      : () {
                          unawaited(onLoadOlder!.call());
                        },
                );
              }

              final messageIndex2 = index - 1;
              final message = messages[messageIndex2];
              final isSelected = selectedMessageIds.contains(
                _messageSelectionKey(message),
              );
              final isHighlighted =
                  highlightedMessageId != null &&
                  highlightedMessageId!.isNotEmpty &&
                  highlightedMessageId == message.messageId;
              final shouldShowTime =
                  messageIndex2 == 0 ||
                  message.sentAt
                          .difference(messages[messageIndex2 - 1].sentAt)
                          .inMinutes
                          .abs() >=
                      5;
              final renderKey = _messageRenderKey(message, messageIndex2);

              return Column(
                key: messageItemKeys[renderKey],
                children: [
                  if (shouldShowTime)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TimeDivider(
                        label: _formatTime(context, message.sentAt),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: messageIndex2 == messages.length - 1 ? 0 : 16,
                    ),
                    child: _MessageRow(
                      messageIndex: messageIndex,
                      message: message,
                      strings: strings,
                      isSelected: isSelected,
                      isHighlighted: isHighlighted,
                      selectionMode: selectionMode,
                      onRetryMessage: onRetryMessage,
                      onOpenMessage: onOpenMessage,
                      onPauseVoiceMessage: onPauseVoiceMessage,
                      onResumeVoiceMessage: onResumeVoiceMessage,
                      onReplayVoiceMessage: onReplayVoiceMessage,
                      onOpenMentionUser: onOpenMentionUser,
                      onOpenQuotedMessage: onOpenQuotedMessage,
                      onOpenLink: onOpenLink,
                      onReeditRecalledMessage: onReeditRecalledMessage,
                      reeditNowTs: reeditNowTs,
                      onOpenReadReceipt: onOpenReadReceipt,
                      onLongPressMessage: onLongPressMessage,
                      onToggleSelection: onToggleSelection,
                      activePlayingVoiceMessageId: activePlayingVoiceMessageId,
                      activePausedVoiceMessageId: activePausedVoiceMessageId,
                      activeVoicePlaybackProgressMs:
                          activeVoicePlaybackProgressMs,
                      activeVoicePlaybackDurationMs:
                          activeVoicePlaybackDurationMs,
                      outgoingFooterLabelBuilder: outgoingFooterLabelBuilder,
                      showSenderNamesForIncoming: showSenderNamesForIncoming,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(BuildContext context, DateTime value) {
    final strings = AppLocalizations.of(context);
    final locale = strings.localeName;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(value.year, value.month, value.day);
    final difference = today.difference(messageDay).inDays;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    if (difference == 0) {
      return strings.chatTimeToday('$hour:$minute');
    }
    if (difference == 1) {
      return strings.chatTimeYesterday('$hour:$minute');
    }
    if (difference > 1 && difference < 7) {
      return DateFormat('E HH:mm', locale).format(value);
    }
    return DateFormat.Md(locale).add_Hm().format(value);
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.messageIndex,
    required this.message,
    required this.strings,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectionMode,
    required this.onRetryMessage,
    required this.onOpenMessage,
    required this.onPauseVoiceMessage,
    required this.onResumeVoiceMessage,
    required this.onReplayVoiceMessage,
    required this.onOpenMentionUser,
    required this.onOpenQuotedMessage,
    this.onOpenLink,
    required this.onReeditRecalledMessage,
    required this.reeditNowTs,
    required this.onOpenReadReceipt,
    required this.onLongPressMessage,
    required this.onToggleSelection,
    required this.activePlayingVoiceMessageId,
    required this.activePausedVoiceMessageId,
    required this.activeVoicePlaybackProgressMs,
    required this.activeVoicePlaybackDurationMs,
    required this.outgoingFooterLabelBuilder,
    required this.showSenderNamesForIncoming,
  });

  final Map<String, Message> messageIndex;
  final Message message;
  final AppLocalizations strings;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final ValueChanged<Message>? onPauseVoiceMessage;
  final ValueChanged<Message>? onResumeVoiceMessage;
  final ValueChanged<Message>? onReplayVoiceMessage;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
  final ValueChanged<String>? onOpenLink;
  final ValueChanged<Message>? onReeditRecalledMessage;
  final int reeditNowTs;
  final ValueChanged<Message>? onOpenReadReceipt;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onToggleSelection;
  final String? activePlayingVoiceMessageId;
  final String? activePausedVoiceMessageId;
  final int activeVoicePlaybackProgressMs;
  final int activeVoicePlaybackDurationMs;
  final String Function(Message message)? outgoingFooterLabelBuilder;
  final bool showSenderNamesForIncoming;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _SystemMessage(
        message: message,
        onReedit: onReeditRecalledMessage,
        reeditNowTs: reeditNowTs,
      );
    }

    final voiceState = _computeVoiceState();
    final quotePreviewChain = _buildQuotePreviewChain(
      messageIndex,
      message,
      context,
    );
    final senderDisplayName = _senderDisplayName(message);

    // 使用 RepaintBoundary 隔离头像渲染，避免气泡变化触发头像重绘
    final avatar = RepaintBoundary(
      child: ChatAvatar(seed: senderDisplayName, imageUrl: message.senderAvatar),
    );

    final bubble = _ChatMessageBubble(
      message: message,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      selectionMode: selectionMode,
      onRetryMessage: onRetryMessage,
      onOpenMessage: onOpenMessage,
      onPauseVoiceMessage: onPauseVoiceMessage,
      onResumeVoiceMessage: onResumeVoiceMessage,
      onReplayVoiceMessage: onReplayVoiceMessage,
      onOpenMentionUser: onOpenMentionUser,
      onOpenQuotedMessage: onOpenQuotedMessage,
      onOpenLink: onOpenLink,
      quotePreviewChain: quotePreviewChain,
      voiceState: voiceState,
      onLongPressMessage: onLongPressMessage,
      onOpenReadReceipt: onOpenReadReceipt,
      onToggleSelection: onToggleSelection,
      outgoingFooterLabelBuilder: outgoingFooterLabelBuilder,
    );

    if (message.isOutgoing) {
      return _OutgoingMessageLayout(
        avatar: avatar,
        bubble: bubble,
      );
    }

    return _IncomingMessageLayout(
      avatar: avatar,
      bubble: bubble,
      senderDisplayName: senderDisplayName,
      showSenderNamesForIncoming: showSenderNamesForIncoming,
    );
  }

  _VoicePlaybackState _computeVoiceState() {
    final isPlaying = activePlayingVoiceMessageId != null &&
        (message.messageId == activePlayingVoiceMessageId ||
            message.clientMessageId == activePlayingVoiceMessageId);
    final isPaused = activePausedVoiceMessageId != null &&
        (message.messageId == activePausedVoiceMessageId ||
            message.clientMessageId == activePausedVoiceMessageId);
    return _VoicePlaybackState(
      isPlaying: isPlaying,
      isPaused: isPaused,
      progressMs: (isPlaying || isPaused) ? activeVoicePlaybackProgressMs : 0,
      durationMs: (isPlaying || isPaused) ? activeVoicePlaybackDurationMs : 0,
    );
  }
}

/// 语音播放状态（提取为独立类，避免重复计算）
class _VoicePlaybackState {
  const _VoicePlaybackState({
    required this.isPlaying,
    required this.isPaused,
    required this.progressMs,
    required this.durationMs,
  });

  final bool isPlaying;
  final bool isPaused;
  final int progressMs;
  final int durationMs;
}

/// 消息气泡组件（RepaintBoundary 隔离，避免外部变化触发重绘）
class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectionMode,
    required this.onRetryMessage,
    required this.onOpenMessage,
    required this.onPauseVoiceMessage,
    required this.onResumeVoiceMessage,
    required this.onReplayVoiceMessage,
    required this.onOpenMentionUser,
    required this.onOpenQuotedMessage,
    this.onOpenLink,
    required this.quotePreviewChain,
    required this.voiceState,
    required this.onLongPressMessage,
    required this.onOpenReadReceipt,
    required this.onToggleSelection,
    required this.outgoingFooterLabelBuilder,
  });

  final Message message;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final ValueChanged<Message>? onPauseVoiceMessage;
  final ValueChanged<Message>? onResumeVoiceMessage;
  final ValueChanged<Message>? onReplayVoiceMessage;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
  final ValueChanged<String>? onOpenLink;
  final List<QuotePreviewEntry> quotePreviewChain;
  final _VoicePlaybackState voiceState;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final ValueChanged<Message>? onToggleSelection;
  final String Function(Message message)? outgoingFooterLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final bubbleContent = RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: (isSelected || isHighlighted) ? 4 : 3,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0x0D07C160)
              : (isHighlighted ? const Color(0x26FFC107) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IgnorePointer(
          ignoring: selectionMode,
          child: MessageBubbleFactory.build(
            message,
            onRetryMessage: onRetryMessage,
            onOpenMessage: onOpenMessage,
            onPauseMessage: onPauseVoiceMessage,
            onResumeMessage: onResumeVoiceMessage,
            onReplayMessage: onReplayVoiceMessage,
            onOpenMentionUser: onOpenMentionUser,
            onOpenQuotedMessage: onOpenQuotedMessage,
            onOpenLink: onOpenLink,
            quotePreviewChain: quotePreviewChain,
            voiceIsPlaying: voiceState.isPlaying,
            voiceIsPaused: voiceState.isPaused,
            voicePlaybackProgressMs: voiceState.progressMs,
            voicePlaybackDurationMs: voiceState.durationMs,
            onLongPressMessage: onLongPressMessage,
            onOpenReadReceipt: onOpenReadReceipt,
            enableReadReceiptEntry: message.isOutgoing,
            showOutgoingStatusFooter: message.isOutgoing,
            outgoingFooterLabel: message.isOutgoing
                ? outgoingFooterLabelBuilder?.call(message)
                : null,
          ),
        ),
      ),
    );

    final canSelect =
        message.type != MessageType.voice &&
        message.type != MessageType.location;
    final messageBody = selectionMode
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggleSelection?.call(message),
            onLongPress: () => onToggleSelection?.call(message),
            child: canSelect
                ? _SelectionWrapper(
                    isOutgoing: message.isOutgoing,
                    isSelected: isSelected,
                    child: bubbleContent,
                  )
                : bubbleContent,
          )
        : bubbleContent;

    return messageBody;
  }
}

/// 出消息布局（右侧头像 + 气泡）
class _OutgoingMessageLayout extends StatelessWidget {
  const _OutgoingMessageLayout({
    required this.avatar,
    required this.bubble,
  });

  final Widget avatar;
  final Widget bubble;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble],
          ),
        ),
        const SizedBox(width: 12),
        avatar,
      ],
    );
  }
}

/// 入消息布局（左侧头像 + 气泡 + 可选的发送者名称）
class _IncomingMessageLayout extends StatelessWidget {
  const _IncomingMessageLayout({
    required this.avatar,
    required this.bubble,
    required this.senderDisplayName,
    required this.showSenderNamesForIncoming,
  });

  final Widget avatar;
  final Widget bubble;
  final String senderDisplayName;
  final bool showSenderNamesForIncoming;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSenderNamesForIncoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8F96A3),
                    ),
                  ),
                ),
              bubble,
            ],
          ),
        ),
      ],
    );
  }
}

List<QuotePreviewEntry> _buildQuotePreviewChain(
  Map<String, Message> messageIndex,
  Message message,
  BuildContext context,
) {
  final strings = AppLocalizations.of(context);
  final quote = message.quoteInfo;
  if (quote == null || quote.messageId.trim().isEmpty) {
    return const <QuotePreviewEntry>[];
  }

  final chain = <QuotePreviewEntry>[];
  var currentId = quote.messageId.trim();
  var currentSender = quote.senderName.trim();
  var currentPreview = quote.preview.trim();
  var depth = 0;
  const maxDepth = 5;

  while (currentId.isNotEmpty && depth < maxDepth) {
    final referenced = messageIndex[currentId];
    if (referenced != null) {
      chain.add(
        QuotePreviewEntry(
          messageId: currentId,
          senderName: referenced.senderName.trim().isNotEmpty
              ? referenced.senderName.trim()
              : (currentSender.isNotEmpty
                    ? currentSender
                    : strings.chatPreviewUnknownSender),
          preview: _messagePreview(referenced, context),
          missing: false,
        ),
      );
      final nextQuote = referenced.quoteInfo;
      if (nextQuote == null || nextQuote.messageId.trim().isEmpty) {
        break;
      }
      currentId = nextQuote.messageId.trim();
      currentSender = nextQuote.senderName.trim();
      currentPreview = nextQuote.preview.trim();
    } else {
      chain.add(
        QuotePreviewEntry(
          messageId: currentId,
          senderName: currentSender.isNotEmpty
              ? currentSender
              : strings.chatPreviewUnknownSender,
          preview: currentPreview.isNotEmpty
              ? currentPreview
              : strings.chatPreviewMessageDeleted,
          missing: true,
        ),
      );
      break;
    }
    depth++;
  }

  return chain;
}

String _messagePreview(Message message, BuildContext context) {
  final strings = AppLocalizations.of(context);
  if (_isRecallPreview(message)) {
    return strings.chatPreviewRecalled;
  }
  switch (message.type) {
    case MessageType.text:
      return message.content;
    case MessageType.image:
      return strings.chatPreviewImage;
    case MessageType.emoji:
      return strings.chatPreviewEmoji;
    case MessageType.sticker:
      return strings.chatPreviewSticker;
    case MessageType.voice:
      return strings.chatPreviewVoice;
    case MessageType.video:
      return strings.chatPreviewVideo;
    case MessageType.file:
      return message.extra.fileName?.trim().isNotEmpty == true
          ? strings.chatPreviewFileWithName(message.extra.fileName!.trim())
          : strings.chatPreviewFile;
    case MessageType.location:
      return strings.chatPreviewLocation;
    case MessageType.contactCard:
      return strings.chatPreviewContactCard;
    case MessageType.custom:
      if (message.extra.customType?.toUpperCase() == 'CONTACT_CARD') {
        return strings.chatPreviewContactCard;
      }
      return message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE'
          ? strings.chatForwardCombine
          : strings.chatCustomMessage;
    case MessageType.system:
      return _resolveSystemMessageText(message, context);
  }
}

bool _isRecallPreview(Message message) {
  if (message.type == MessageType.system &&
      (message.content.contains('撤回') ||
          message.extra.systemEventKey == 'im.system.message_recalled')) {
    return true;
  }
  return false;
}

String _resolveSystemMessageText(Message message, BuildContext context) {
  final content = message.content.trim();
  if (content.isNotEmpty && !content.startsWith('im.system.')) {
    return content;
  }
  
  // Use SystemMessageRenderer for personalized rendering with params
  final systemEventKey = content.startsWith('im.system.') 
      ? content 
      : message.extra.systemEventKey;
  
  return SystemMessageRenderer.render(
    context,
    systemEventKey,
    params: message.extra.systemEventParams,
    fallbackContent: content,
  );
}

class _SelectionWrapper extends StatelessWidget {
  const _SelectionWrapper({
    required this.isOutgoing,
    required this.isSelected,
    required this.child,
  });

  final bool isOutgoing;
  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF07C160)
                  : const Color(0xFFD3DAE6),
              width: 1.25,
            ),
            boxShadow: isSelected
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: isSelected
              ? const AppIcon(
                  AppIconKind.check,
                  size: 14,
                  color: Color(0xFF07C160),
                )
              : null,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isOutgoing
          ? [Flexible(child: child), const SizedBox(width: 4), indicator]
          : [indicator, const SizedBox(width: 4), Flexible(child: child)],
    );
  }
}

class _TimeDivider extends StatelessWidget {
  const _TimeDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x0D1F2329),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF98A1B2)),
      ),
    );
  }
}

String _senderDisplayName(Message message) {
  final senderName = message.senderName.trim();
  if (senderName.isNotEmpty) {
    return senderName;
  }
  final senderId = message.senderId.trim();
  if (senderId.isNotEmpty) {
    return senderId;
  }
  final chatId = message.chatId.trim();
  if (chatId.isNotEmpty) {
    return chatId;
  }
  return '?';
}

String _messageSelectionKey(Message message) {
  final messageId = message.messageId.trim();
  if (messageId.isNotEmpty) {
    return messageId;
  }
  return message.clientMessageId?.trim() ?? '';
}

String _messageRenderKey(Message message, int index) {
  final messageId = message.messageId.trim();
  final clientMessageId = message.clientMessageId?.trim() ?? '';
  final sequence = message.sequence?.trim() ?? '';
  // 使用稳定标识符，不依赖索引，避免加载历史消息后 key 失效
  if (sequence.isNotEmpty) {
    return 'seq:$sequence';
  }
  if (messageId.isNotEmpty && clientMessageId.isNotEmpty) {
    return 'mid:$messageId|cid:$clientMessageId';
  }
  if (messageId.isNotEmpty) {
    return 'mid:$messageId';
  }
  if (clientMessageId.isNotEmpty) {
    return 'cid:$clientMessageId';
  }
  return 'idx:$index@${message.sentAt.microsecondsSinceEpoch}';
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({
    required this.message,
    required this.reeditNowTs,
    this.onReedit,
  });

  final Message message;
  final int reeditNowTs;
  final ValueChanged<Message>? onReedit;

  @override
  Widget build(BuildContext context) {
    final canReedit = _canReeditMessage(message);
    final strings = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0F1F2329),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _resolveSystemMessageText(message, context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7380),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (canReedit)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => onReedit?.call(message),
                  child: Text(
                    strings.chatReeditAction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3370FF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canReeditMessage(Message message) {
    if (!message.isOutgoing) {
      return false;
    }
    final reeditContent = message.extra.reeditContent?.trim() ?? '';
    final reeditDeadlineTs = message.extra.reeditDeadlineTs ?? 0;
    if (reeditContent.isEmpty || reeditDeadlineTs <= 0) {
      return false;
    }
    if (message.extra.quoteMessageId?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.forwardedFrom?.trim().isNotEmpty == true) {
      return false;
    }
    if (message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE') {
      return false;
    }
    return reeditNowTs <= reeditDeadlineTs;
  }
}

class _LoadOlderBar extends StatelessWidget {
  const _LoadOlderBar({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 如果没有onTap回调，说明没有更多消息，不显示任何内容
    if (onTap == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B7380),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context).chatLoadOlder),
        ),
      ),
    );
  }
}

class _ChatWatermarkLayer extends StatelessWidget {
  const _ChatWatermarkLayer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Opacity(
      opacity: 0.03,
      child: Transform.rotate(
        angle: -25 * 3.1415926 / 180,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runAlignment: WrapAlignment.spaceAround,
            spacing: 8,
            runSpacing: 24,
            children: List<Widget>.generate(
              12,
              (index) => Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
