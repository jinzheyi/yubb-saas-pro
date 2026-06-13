import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 语音消息气泡组件
/// 已消除 ConsumerWidget 依赖，strings 从父组件传入，避免对 appStringsProvider 的不必要订阅
class VoiceMessageBubble extends StatelessWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.strings,
    required this.onRetryMessage,
    required this.onOpenMessage,
    this.onPauseMessage,
    this.onResumeMessage,
    this.onReplayMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
    this.isPlaying = false,
    this.isPaused = false,
    this.playbackProgressMs = 0,
    this.playbackDurationMs = 0,
  });

  final Message message;
  final AppLocalizations strings;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final ValueChanged<Message>? onPauseMessage;
  final ValueChanged<Message>? onResumeMessage;
  final ValueChanged<Message>? onReplayMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;
  final bool isPlaying;
  final bool isPaused;
  final int playbackProgressMs;
  final int playbackDurationMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationMs = _resolveDurationMs();
    final durationLabel = _durationLabel(durationMs);
    final unread = message.isOutgoing
        ? false
        : !(message.extra.voicePlayed ?? false);
    final bubbleBackground = _bubbleBackground(context);
    final borderColor = _borderColor(context);
    final primaryTextColor = message.isOutgoing
        ? ThemeColors.chatBubbleIncomingText(context).withValues(alpha: 0.7)
        : ThemeColors.chatBubbleIncomingText(context);
    final waveColor = isPlaying || isPaused
        ? (message.isOutgoing
              ? ThemeColors.chatBubbleIncomingText(context).withValues(alpha: 0.7)
              : ThemeColors.chatBubbleIncomingText(context))
        : ThemeColors.textSecondary(context);
    final progressColor = message.isOutgoing
        ? ThemeColors.chatBubbleIncomingText(context).withValues(alpha: 0.7)
        : ThemeColors.chatBubbleIncomingText(context);
    final progressTrackColor = message.isOutgoing
        ? ThemeColors.chatBubbleIncomingText(context).withValues(alpha: 0.16)
        : ThemeColors.textSecondary(context).withValues(alpha: 0.12);
    final bars = _waveHeights();
    final bubbleWidth = _bubbleWidth(durationMs);
    final unreadDot = !message.isOutgoing && unread;
    final canControlPlayback = !_hasSendErrorOrLoading();
    final controlIcon = isPlaying ? AppIconKind.pause : AppIconKind.play;
    final controlColor = message.isOutgoing
        ? ThemeColors.chatBubbleIncomingText(context).withValues(alpha: 0.7)
        : ThemeColors.chatBubbleIncomingText(context);
    final canReplay =
        canControlPlayback &&
        (message.extra.fileUrl?.trim().isNotEmpty == true ||
            message.extra.fileId?.trim().isNotEmpty == true ||
            message.extra.localPath?.trim().isNotEmpty == true);

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: GestureDetector(
                onLongPressStart: onLongPressMessage == null
                    ? null
                    : (details) =>
                          onLongPressMessage!(message, details.globalPosition),
                child: InkWell(
                  onTap: () => onOpenMessage(message),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: bubbleWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleBackground,
                      border: borderColor == null
                          ? null
                          : Border.all(color: borderColor),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(
                          message.isOutgoing ? 12 : 5,
                        ),
                        bottomRight: Radius.circular(
                          message.isOutgoing ? 5 : 12,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      textDirection: message.isOutgoing
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      children: [
                        if (canControlPlayback) ...[
                          _buildIconButton(
                            context: context,
                            icon: controlIcon,
                            color: controlColor,
                            filled: isPlaying || isPaused,
                            onTap: () {
                              if (isPlaying) {
                                onPauseMessage?.call(message);
                                return;
                              }
                              if (isPaused) {
                                onResumeMessage?.call(message);
                                return;
                              }
                              onOpenMessage(message);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        SizedBox(
                          height: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final height in bars)
                                Container(
                                  width: 2,
                                  height: height.toDouble(),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: waveColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final canShowProgress =
                                  (isPlaying || isPaused) &&
                                  availableWidth >= 72;
                              final textWidget = Text(
                                durationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: primaryTextColor,
                                ),
                              );
                              if (availableWidth < 44) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: textWidget,
                                );
                              }
                              return Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(child: textWidget),
                                  if (canShowProgress) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          minHeight: 3,
                                          value: _progressValue(durationMs),
                                          backgroundColor: progressTrackColor,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                progressColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        if (canReplay) ...[
                          const SizedBox(width: 8),
                          _buildIconButton(
                            context: context,
                            icon: AppIconKind.refresh,
                            color: controlColor,
                            filled: isPlaying || isPaused,
                            onTap: () => onReplayMessage?.call(message),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (unreadDot) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ThemeColors.errorText(context),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: ThemeColors.scaffoldBg(context), width: 1),
                  ),
                ),
              ),
            ],
          ],
        ),
        MessageStatusFooter(
          message: message,
          onRetryMessage: onRetryMessage,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          showOutgoingStatusFooter: showOutgoingStatusFooter,
          outgoingFooterLabel: outgoingFooterLabel,
        ),
      ],
    );
  }

  String _durationLabel(int durationMs) {
    final totalMs = durationMs <= 0 ? 1000 : durationMs;
    final totalSeconds = (totalMs / 1000).round().clamp(1, 3600);
    if (!isPlaying && !isPaused) {
      return '${totalSeconds}s';
    }
    final playedMs = playbackProgressMs.clamp(0, totalMs);
    final playedSeconds = (playedMs / 1000).floor().clamp(0, totalSeconds);
    return '${playedSeconds}s / ${totalSeconds}s';
  }

  double? _progressValue(int durationMs) {
    final totalMs = playbackDurationMs > 0 ? playbackDurationMs : durationMs;
    if (totalMs <= 0) {
      return null;
    }
    final currentMs = playbackProgressMs.clamp(0, totalMs);
    return currentMs / totalMs;
  }

  List<int> _waveHeights() {
    if (!isPlaying) {
      return const [6, 10, 14, 10, 6];
    }
    const frames = <List<int>>[
      [6, 10, 14, 10, 6],
      [9, 13, 8, 12, 7],
      [12, 8, 14, 9, 11],
      [7, 14, 10, 13, 8],
    ];
    final frameIndex = ((playbackProgressMs ~/ 180) % frames.length).clamp(
      0,
      frames.length - 1,
    );
    return frames[frameIndex];
  }

  Widget _buildIconButton({
    required BuildContext context,
    required AppIconKind icon,
    required Color color,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? (message.isOutgoing
                    ? ThemeColors.scaffoldBg(context).withValues(alpha: 0.19)
                    : ThemeColors.noticeBg(context))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: AppIcon(icon, size: 13, color: color),
      ),
    );
  }

  double _bubbleWidth(int durationMs) {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 60);
    const minWidth = 136.0;
    double width;
    if (durationSeconds <= 10) {
      width = minWidth + (durationSeconds - 1) * 6.0;
    } else if (durationSeconds <= 30) {
      width = minWidth + 9 * 6.0 + (durationSeconds - 10) * 2.8;
    } else {
      width = minWidth + 9 * 6.0 + 20 * 2.8 + (durationSeconds - 30) * 1.8;
    }
    return width.clamp(minWidth, 248.0);
  }

  int _resolveDurationMs() {
    final fromExtra = message.extra.durationMs ?? 0;
    if (fromExtra > 0) {
      return fromExtra;
    }
    final fromSeconds = (message.extra.duration ?? 0) * 1000;
    if (fromSeconds > 0) {
      return fromSeconds;
    }
    return 1000;
  }

  bool _hasSendErrorOrLoading() {
    return message.status == MessageStatus.sending ||
        message.status == MessageStatus.failed;
  }

  Color _bubbleBackground(BuildContext context) {
    if (isPlaying) {
      return message.isOutgoing
          ? const Color(0xFFC8DCF8)
          : const Color(0xFFEDF4FF);
    }
    if (isPaused) {
      return message.isOutgoing
          ? const Color(0xFFD2E3FC)
          : ThemeColors.surfaceDim(context);
    }
    return message.isOutgoing
        ? const Color(0xFFD2E3FC)
        : ThemeColors.chatBubbleIncoming(context);
  }

  Color? _borderColor(BuildContext context) {
    if (message.status == MessageStatus.failed) {
      return ThemeColors.errorText(context).withValues(alpha: 0.35);
    }
    if (message.isOutgoing) {
      return const Color(0xFFB2CFFB);
    }
    return ThemeColors.divider(context).withValues(alpha: 0.5);
  }
}
