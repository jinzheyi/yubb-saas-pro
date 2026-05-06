import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
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
    this.onOpenMentionUser,
    this.onOpenQuotedMessage,
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
  });

  final List<Message> messages;
  final Map<String, GlobalKey> messageItemKeys;
  final ScrollController? controller;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await onLoadOlder?.call();
      },
      child: ListView.builder(
        controller: controller,
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

          final messageIndex = index - 1;
          final message = messages[messageIndex];
          final isSelected = selectedMessageIds.contains(
            _messageSelectionKey(message),
          );
          final isHighlighted =
              highlightedMessageId != null &&
              highlightedMessageId!.isNotEmpty &&
              highlightedMessageId == message.messageId;
          final shouldShowTime =
              messageIndex == 0 ||
              message.sentAt
                      .difference(messages[messageIndex - 1].sentAt)
                      .inMinutes
                      .abs() >=
                  5;

          return Column(
            key:
                messageItemKeys[_messageSelectionKey(message)] ??
                messageItemKeys[message.messageId] ??
                (message.clientMessageId == null
                    ? null
                    : messageItemKeys[message.clientMessageId!]),
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
                  bottom: messageIndex == messages.length - 1 ? 0 : 16,
                ),
                child: _MessageRow(
                  messages: messages,
                  message: message,
                  strings: strings,
                  isSelected: isSelected,
                  isHighlighted: isHighlighted,
                  selectionMode: selectionMode,
                  onRetryMessage: onRetryMessage,
                  onOpenMessage: onOpenMessage,
                  onOpenMentionUser: onOpenMentionUser,
                  onOpenQuotedMessage: onOpenQuotedMessage,
                  onReeditRecalledMessage: onReeditRecalledMessage,
                  reeditNowTs: reeditNowTs,
                  onOpenReadReceipt: onOpenReadReceipt,
                  onLongPressMessage: onLongPressMessage,
                  onToggleSelection: onToggleSelection,
                  activePlayingVoiceMessageId: activePlayingVoiceMessageId,
                  activePausedVoiceMessageId: activePausedVoiceMessageId,
                  activeVoicePlaybackProgressMs: activeVoicePlaybackProgressMs,
                  activeVoicePlaybackDurationMs:
                      activeVoicePlaybackDurationMs,
                  outgoingFooterLabelBuilder: outgoingFooterLabelBuilder,
                ),
              ),
            ],
          );
        },
      ),
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
    required this.messages,
    required this.message,
    required this.strings,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectionMode,
    required this.onRetryMessage,
    required this.onOpenMessage,
    required this.onOpenMentionUser,
    required this.onOpenQuotedMessage,
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
  });

  final List<Message> messages;
  final Message message;
  final AppLocalizations strings;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final void Function(String userId, String displayName)? onOpenMentionUser;
  final ValueChanged<String>? onOpenQuotedMessage;
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

  @override
  Widget build(BuildContext context) {
    final quotePreviewChain = _buildQuotePreviewChain(
      messages,
      message,
      strings,
    );
    if (message.type == MessageType.system) {
      return _SystemMessage(
        message: message,
        onReedit: onReeditRecalledMessage,
        reeditNowTs: reeditNowTs,
      );
    }

    final bubble = AnimatedContainer(
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
          onOpenMentionUser: onOpenMentionUser,
          onOpenQuotedMessage: onOpenQuotedMessage,
          quotePreviewChain: quotePreviewChain,
          voiceIsPlaying:
              activePlayingVoiceMessageId != null &&
              (message.messageId == activePlayingVoiceMessageId ||
                  message.clientMessageId == activePlayingVoiceMessageId),
          voiceIsPaused:
              activePausedVoiceMessageId != null &&
              (message.messageId == activePausedVoiceMessageId ||
                  message.clientMessageId == activePausedVoiceMessageId),
          voicePlaybackProgressMs:
              (activePlayingVoiceMessageId != null &&
                      (message.messageId == activePlayingVoiceMessageId ||
                          message.clientMessageId ==
                              activePlayingVoiceMessageId)) ||
                  (activePausedVoiceMessageId != null &&
                      (message.messageId == activePausedVoiceMessageId ||
                          message.clientMessageId ==
                              activePausedVoiceMessageId))
              ? activeVoicePlaybackProgressMs
              : 0,
          voicePlaybackDurationMs:
              (activePlayingVoiceMessageId != null &&
                      (message.messageId == activePlayingVoiceMessageId ||
                          message.clientMessageId ==
                              activePlayingVoiceMessageId)) ||
                  (activePausedVoiceMessageId != null &&
                      (message.messageId == activePausedVoiceMessageId ||
                          message.clientMessageId ==
                              activePausedVoiceMessageId))
              ? activeVoicePlaybackDurationMs
              : 0,
          onLongPressMessage: onLongPressMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: message.isOutgoing,
          showOutgoingStatusFooter: message.isOutgoing,
          outgoingFooterLabel: message.isOutgoing
              ? outgoingFooterLabelBuilder?.call(message)
              : null,
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
                    child: bubble,
                  )
                : bubble,
          )
        : bubble;

    if (message.isOutgoing) {
      return Align(
        alignment: Alignment.centerRight,
        child: messageBody,
      );
    }

    final senderDisplayName = _senderDisplayName(message);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(seed: senderDisplayName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              messageBody,
            ],
          ),
        ),
      ],
    );
  }

}

List<QuotePreviewEntry> _buildQuotePreviewChain(
  List<Message> messages,
  Message message,
  AppLocalizations strings,
) {
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
    final referenced = messages
        .where((item) => item.messageId == currentId)
        .firstOrNull;
    if (referenced != null) {
      chain.add(
        QuotePreviewEntry(
          messageId: currentId,
          senderName: referenced.senderName.trim().isNotEmpty
              ? referenced.senderName.trim()
              : (currentSender.isNotEmpty
                    ? currentSender
                    : strings.chatPreviewUnknownSender),
          preview: _messagePreview(referenced, strings),
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

String _messagePreview(Message message, AppLocalizations strings) {
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
      return message.extra.customType?.toUpperCase() == 'FORWARD_COMBINE'
          ? strings.chatForwardCombine
          : strings.chatCustomMessage;
    case MessageType.system:
      return _resolveSystemMessageText(message, strings);
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

String _resolveSystemMessageText(Message message, AppLocalizations strings) {
  final content = message.content.trim();
  if (content.isNotEmpty) {
    return content;
  }
  switch (message.extra.systemEventKey) {
    case 'im.system.group_notice_updated':
      return strings.chatGroupNoticeUpdated;
    case 'im.system.group_mute_all_enabled':
      return strings.chatGroupMuteAllEnabled;
    case 'im.system.group_mute_all_disabled':
      return strings.chatGroupMuteAllDisabled;
    case 'im.system.group_member_added_one':
    case 'im.system.group_member_added_two':
    case 'im.system.group_member_added_many':
      return strings.chatGroupMemberAdded;
    case 'im.system.group_member_removed':
      return strings.chatGroupMemberRemoved;
    case 'im.system.group_owner_transferred':
      return strings.chatGroupOwnerTransferred;
    case 'im.system.group_member_role_set_admin':
      return strings.chatGroupMemberRoleSetAdmin;
    case 'im.system.group_member_role_set_member':
      return strings.chatGroupMemberRoleSetMember;
    case 'im.system.group_member_muted':
    case 'im.system.group_member_muted_until':
      return strings.chatGroupMemberMutedGeneric;
    case 'im.system.group_member_unmuted':
      return strings.chatGroupMemberUnmutedGeneric;
    default:
      return strings.chatPreviewMessage;
  }
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
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF98A1B2),
        ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x0F1F2329),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _resolveSystemMessageText(message, strings),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7380),
                  height: 1.5,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final initials = seed.isEmpty ? '?' : seed.substring(0, 1);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _avatarColor(seed),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _avatarColor(String seed) {
    const colors = <Color>[
      Color(0xFFE97CAB),
      Color(0xFF93D3A8),
      Color(0xFFF6CFA9),
      Color(0xFF8FB8F7),
    ];
    return colors[seed.isEmpty ? 0 : seed.codeUnitAt(0) % colors.length];
  }
}
