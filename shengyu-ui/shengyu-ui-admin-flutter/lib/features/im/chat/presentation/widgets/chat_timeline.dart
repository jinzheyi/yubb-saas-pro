import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_record_display_text.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/core/i18n/system_message_renderer.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_preview_entry.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_key_cache.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/chat_avatar.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_bubble_factory.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatTimeline extends StatelessWidget {
  const ChatTimeline({
    super.key,
    required this.messages,
    this.messageItemKeys,
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
    this.quotePreviewCache = const <String, List<QuotePreviewEntry>>{},
  });

  final List<Message> messages;
  final MessageKeyCache? messageItemKeys;
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

  /// 引用链预计算缓存，由 controller 在消息合并时自动更新
  /// 渲染时直接读取缓存，无需在 build 中遍历引用链
  final Map<String, List<QuotePreviewEntry>> quotePreviewCache;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: _ChatWatermarkLayer(text: watermarkText ?? '')),
        RefreshIndicator(
          onRefresh: () async {
            await onLoadOlder?.call();
          },
          // 使用 CustomScrollView + SliverList.builder 替代 ListView.builder，
          // reverse: true 使消息列表从底部开始渲染，新消息自动出现在底部
          child: CustomScrollView(
            reverse: true,
            // 设置预渲染区域，提升上下滚动时的性能
            // ignore: deprecated_member_use
            cacheExtent: 500.0,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 添加底部内边距，替代 ListView 的 padding.bottom
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              // 加载更多历史消息的触发区域
              SliverToBoxAdapter(
                child: _LoadOlderBar(
                  isLoading: isLoadingOlder,
                  onTap: onLoadOlder == null
                      ? null
                      : () {
                          unawaited(onLoadOlder!.call());
                        },
                ),
              ),
              SliverList.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  // reverse 模式: index 0 → messages[length-1]（最新消息），
                  // index length-1 → messages[0]（最旧消息）
                  final messageIndex2 = messages.length - 1 - index;
                  final message = messages[messageIndex2];
                  final isSelected = selectedMessageIds.contains(
                    _messageSelectionKey(message),
                  );
                  final isHighlighted =
                      highlightedMessageId != null &&
                      highlightedMessageId!.isNotEmpty &&
                      highlightedMessageId == message.messageId;
                  // 消息间隔 ≥ 5 分钟时显示时间戳
                  final shouldShowTime =
                      messageIndex2 == messages.length - 1 ||
                      message.sentAt
                              .difference(messages[messageIndex2 + 1].sentAt)
                              .inMinutes
                              .abs() >=
                          5;
                  final renderKey = _messageRenderKey(message, messageIndex2);

                  // 使用 KeyedSubtree 同时支持 GlobalKey（外部引用）和 ValueKey（列表项稳定标识）
                  // KeyedSubtree(key: GlobalKey) → KeyedSubtree(key: ValueKey) → _ChatMessageItem
                  return KeyedSubtree(
                    key: messageItemKeys?[renderKey],
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        _messageStableKey(message, messageIndex2),
                      ),
                      child: _ChatMessageItem(
                        message: message,
                        quotePreviewChain:
                            quotePreviewCache[message.messageId] ??
                            const <QuotePreviewEntry>[],
                        strings: strings,
                        isSelected: isSelected,
                        isHighlighted: isHighlighted,
                        shouldShowTime: shouldShowTime,
                        formatTime: (t) => _formatTime(context, t),
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
                        activePlayingVoiceMessageId:
                            activePlayingVoiceMessageId,
                        activePausedVoiceMessageId: activePausedVoiceMessageId,
                        activeVoicePlaybackProgressMs:
                            activeVoicePlaybackProgressMs,
                        activeVoicePlaybackDurationMs:
                            activeVoicePlaybackDurationMs,
                        outgoingFooterLabelBuilder: outgoingFooterLabelBuilder,
                        showSenderNamesForIncoming: showSenderNamesForIncoming,
                      ),
                    ),
                  );
                },
              ),
              // 添加顶部内边距，替代 ListView 的 padding.top + padding.horizontal
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                sliver: SliverToBoxAdapter(child: Container()),
              ),
            ],
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

/// 生成稳定的消息渲染 Key，不随 rebuild 变化
/// 使用 messageId + sentAt 组合，确保 ValueKey 稳定
String _messageStableKey(Message message, int index) {
  final messageId = message.messageId.trim();
  final clientMessageId = message.clientMessageId?.trim() ?? '';
  final sequence = message.sequence?.trim() ?? '';
  // 优先级: sequence > messageId+clientMessageId > messageId > clientMessageId > 兜底
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
  // 兜底方案：使用 sentAt 时间戳作为唯一标识
  return 'ts:${message.sentAt.millisecondsSinceEpoch}@idx:$index';
}

/// 消息条目组件（扁平化结构，减少 Widget 树深度）
class _ChatMessageItem extends StatelessWidget {
  const _ChatMessageItem({
    required this.message,
    this.quotePreviewChain = const <QuotePreviewEntry>[],
    required this.strings,
    required this.isSelected,
    required this.isHighlighted,
    required this.shouldShowTime,
    required this.formatTime,
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

  final Message message;

  /// 预计算的引用链列表，由 controller 在消息合并时自动计算，build 中直接使用
  final List<QuotePreviewEntry> quotePreviewChain;
  final AppLocalizations strings;
  final bool isSelected;
  final bool isHighlighted;
  final bool shouldShowTime;
  final String Function(DateTime) formatTime;
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
    // 系统消息单独渲染
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _SystemMessage(
          message: message,
          onReedit: onReeditRecalledMessage,
          reeditNowTs: reeditNowTs,
        ),
      );
    }

    // 通话记录消息：群聊居中显示，1v1 气泡显示
    if (message.type == MessageType.callRecord) {
      final isGroupCall = message.extra.isGroupCall ?? false;
      if (isGroupCall) {
        // 群聊通话记录：居中系统消息样式
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _CallRecordCenteredMessage(message: message),
        );
      }
      // 1v1 通话记录：走正常气泡渲染流程
    }

    final voiceState = _computeVoiceState();
    // 直接使用预计算的引用链，无需在 build 中遍历引用链
    final senderDisplayName = _senderDisplayName(message);

    // 头像区域独立 RepaintBoundary，避免气泡变化触发头像重绘
    // 使用 senderId 作为 seed 确保头像颜色稳定，使用 senderDisplayName 作为 name 显示文字头像
    final avatar = RepaintBoundary(
      child: ChatAvatar(
        seed: message.senderId,
        name: senderDisplayName,
        imageUrl: message.senderAvatar,
      ),
    );

    // 气泡内容独立 RepaintBoundary
    final bubble = _ChatMessageBubble(
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
      quotePreviewChain: quotePreviewChain,
      voiceState: voiceState,
      onLongPressMessage: onLongPressMessage,
      onOpenReadReceipt: onOpenReadReceipt,
      onToggleSelection: onToggleSelection,
      outgoingFooterLabelBuilder: outgoingFooterLabelBuilder,
    );

    Widget messageRow;
    if (message.isOutgoing) {
      messageRow = _OutgoingMessageLayout(avatar: avatar, bubble: bubble);
    } else {
      messageRow = _IncomingMessageLayout(
        avatar: avatar,
        bubble: bubble,
        senderDisplayName: senderDisplayName,
        showSenderNamesForIncoming: showSenderNamesForIncoming,
      );
    }

    // 时间戳与消息合并渲染，使用 RepaintBoundary 隔离
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shouldShowTime)
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Center(
                  child: _TimeDivider(label: formatTime(message.sentAt)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: messageRow,
          ),
        ],
      ),
    );
  }

  _VoicePlaybackState _computeVoiceState() {
    final isPlaying =
        activePlayingVoiceMessageId != null &&
        (message.messageId == activePlayingVoiceMessageId ||
            message.clientMessageId == activePlayingVoiceMessageId);
    final isPaused =
        activePausedVoiceMessageId != null &&
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
/// 已移除 AnimatedContainer，使用条件样式直接切换
class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
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
    required this.quotePreviewChain,
    required this.voiceState,
    required this.onLongPressMessage,
    required this.onOpenReadReceipt,
    required this.onToggleSelection,
    required this.outgoingFooterLabelBuilder,
  });

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
  final List<QuotePreviewEntry> quotePreviewChain;
  final _VoicePlaybackState voiceState;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final ValueChanged<Message>? onToggleSelection;
  final String Function(Message message)? outgoingFooterLabelBuilder;

  @override
  Widget build(BuildContext context) {
    // 使用普通 Container 替代 AnimatedContainer，通过条件样式直接切换状态
    final bubbleContent = RepaintBoundary(
      child: Container(
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
            strings: strings,
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
  const _OutgoingMessageLayout({required this.avatar, required this.bubble});

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

/// 选中态指示器组件（已移除 AnimatedContainer，使用条件样式直接切换）
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
    // 使用普通 Container 替代 AnimatedContainer，直接切换样式
    final indicator = SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Container(
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

/// 时间分隔线组件（独立 RepaintBoundary 隔离渲染）
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
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

/// 群聊通话记录居中消息组件
///
/// 参考微信群聊通话记录显示逻辑：
/// - 发起通话："{发起人}发起了{语音/视频}通话"
/// - 通话结束："{语音/视频}通话已经结束"
/// 样式：居中显示，灰色文字，无气泡背景
class _CallRecordCenteredMessage extends StatelessWidget {
  const _CallRecordCenteredMessage({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final displayText = _buildDisplayText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// 构建展示文本（微信风格）
  String _buildDisplayText(BuildContext context) {
    final extra = message.extra;
    // 优先使用 extra.callerName，其次才是 senderName
    final callerName = extra.callerName?.isNotEmpty == true
        ? extra.callerName!
        : (message.senderName.isNotEmpty ? message.senderName : '对方');
    final callStatus = extra.callStatus ?? 1;
    final isGroupCall = extra.isGroupCall ?? false;
    final duration = extra.duration ?? 0;

    return callRecordDisplayText(
      strings: AppLocalizations.of(context),
      callType: (extra.callType ?? 1) == 2 ? CallType.video : CallType.audio,
      status: CallStatus.fromValue(callStatus),
      durationSeconds: duration,
      isGroupCall: isGroupCall,
      isOutgoing: message.isOutgoing,
      callerName: callerName,
    );
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
            children: _buildWatermarkItems(text),
          ),
        ),
      ),
    );
  }

  /// 缓存水印子组件，避免每次 build 都重新创建 12 个 Text 组件
  static final Map<String, List<Widget>> _cachedItems =
      <String, List<Widget>>{};

  List<Widget> _buildWatermarkItems(String text) {
    // 如果该文本已缓存，直接返回缓存结果
    if (_cachedItems.containsKey(text)) {
      return _cachedItems[text]!;
    }
    // 构建并缓存水印子组件
    final items = List<Widget>.generate(
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
    );
    // 限制缓存大小，避免内存泄漏（最多缓存 5 个不同的文本）
    if (_cachedItems.length >= 5) {
      _cachedItems.remove(_cachedItems.keys.first);
    }
    _cachedItems[text] = items;
    return items;
  }
}
