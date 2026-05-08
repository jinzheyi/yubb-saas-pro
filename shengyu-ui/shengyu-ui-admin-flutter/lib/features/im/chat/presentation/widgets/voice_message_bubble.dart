import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class VoiceMessageBubble extends ConsumerWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final durationMs = _resolveDurationMs();
    final durationLabel = _durationLabel(durationMs);
    final unread = message.isOutgoing
        ? false
        : !(message.extra.voicePlayed ?? false);
    final bubbleBackground = _bubbleBackground();
    final borderColor = _borderColor();
    final primaryTextColor = message.isOutgoing
        ? const Color(0xFF0F4AA3)
        : const Color(0xFF202531);
    final statusTextColor = message.isOutgoing
        ? const Color(0xFF0F4AA3)
        : const Color(0xFF606973);
    final waveColor = isPlaying
        ? (message.isOutgoing
              ? const Color(0xFF0F4AA3)
              : const Color(0xFF1677FF))
        : const Color(0xFF606973);
    final progressColor = message.isOutgoing
        ? const Color(0xFF0F4AA3)
        : const Color(0xFF1677FF);
    final progressTrackColor = message.isOutgoing
        ? const Color(0x290F4AA3)
        : const Color(0x1F1F2329);
    final bars = _waveHeights();
    final bubbleWidth = _bubbleWidth(durationMs);
    final showInlinePausedActions = isPaused && !_hasSendErrorOrLoading();
    final showTapControlIcon =
        (isPlaying || isPaused) && !_hasSendErrorOrLoading();
    final unreadDot = !message.isOutgoing && unread;

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.isOutgoing)
          _OutgoingStatusRow(message: message, onRetryMessage: onRetryMessage),
        const SizedBox(height: 4),
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
                      horizontal: 10,
                      vertical: 9,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                durationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                              ),
                              if (isPlaying || isPaused) ...[
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    value: _progressValue(durationMs),
                                    backgroundColor: progressTrackColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor,
                                    ),
                                  ),
                                ),
                              ],
                              if (showInlinePausedActions) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: onResumeMessage == null
                                          ? null
                                          : () => onResumeMessage!(message),
                                      child: _buildActionChip(
                                        label: '继续播放',
                                        outlined: true,
                                      ),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: onReplayMessage == null
                                          ? null
                                          : () => onReplayMessage!(message),
                                      child: _buildActionChip(
                                        label: '重播',
                                        outlined: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((_statusLabelText() ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _statusLabelText()!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: statusTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showTapControlIcon) ...[
                          const SizedBox(width: 8),
                          AppIcon(
                            isPlaying ? AppIconKind.pause : AppIconKind.play,
                            size: 16,
                            color: message.isOutgoing
                                ? const Color(0xFF0F4AA3)
                                : const Color(0xFF1677FF),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5B5B),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (message.isOutgoing && showOutgoingStatusFooter)
          const SizedBox(height: 4),
        if (message.isOutgoing && showOutgoingStatusFooter)
          GestureDetector(
            onTap:
                enableReadReceiptEntry &&
                    message.status != MessageStatus.sending &&
                    message.status != MessageStatus.failed
                ? () => onOpenReadReceipt?.call(message)
                : null,
            child: Text(
              outgoingFooterLabel ?? _statusLabel(strings),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: _statusColor(theme),
              ),
            ),
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

  Widget _buildActionChip({required String label, required bool outlined}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined
            ? (message.isOutgoing ? Colors.white : const Color(0xFFF7F9FC))
            : (message.isOutgoing
                  ? const Color(0x260F4AA3)
                  : const Color(0x1F1677FF)),
        borderRadius: BorderRadius.circular(14),
        border: outlined
            ? Border.all(
                color: message.isOutgoing
                    ? const Color(0xFFB2CFFB)
                    : const Color(0xFFE2E7EF),
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: message.isOutgoing
              ? const Color(0xFF0F4AA3)
              : const Color(0xFF1677FF),
        ),
      ),
    );
  }

  double _bubbleWidth(int durationMs) {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 60);
    const minWidth = 92.0;
    double width;
    if (durationSeconds <= 10) {
      width = minWidth + (durationSeconds - 1) * 5.4;
    } else if (durationSeconds <= 30) {
      width = minWidth + 9 * 5.4 + (durationSeconds - 10) * 2.8;
    } else {
      width = minWidth + 9 * 5.4 + 20 * 2.8 + (durationSeconds - 30) * 1.9;
    }
    return width.clamp(minWidth, 236.0);
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

  String? _statusLabelText() {
    if (message.status == MessageStatus.sending) {
      return '发送中';
    }
    if (message.status == MessageStatus.failed) {
      return '发送失败';
    }
    return null;
  }

  bool _hasSendErrorOrLoading() {
    return message.status == MessageStatus.sending ||
        message.status == MessageStatus.failed;
  }

  Color _bubbleBackground() {
    if (isPlaying) {
      return message.isOutgoing
          ? const Color(0xFFC3D9FF)
          : const Color(0xFFEDF4FF);
    }
    if (isPaused) {
      return message.isOutgoing
          ? const Color(0xFFC8DCF8)
          : const Color(0xFFF4F6FA);
    }
    return message.isOutgoing ? const Color(0xFFD2E3FC) : Colors.white;
  }

  Color? _borderColor() {
    if (message.status == MessageStatus.failed) {
      return const Color(0x59F54A45);
    }
    if (message.isOutgoing) {
      return const Color(0xFFB2CFFB);
    }
    return const Color(0xFFEFF2F6);
  }

  String _statusLabel(AppLocalizations strings) {
    switch (message.status) {
      case MessageStatus.sending:
        return strings.messageSending;
      case MessageStatus.sent:
        return strings.messageSent;
      case MessageStatus.delivered:
        return strings.messageDelivered;
      case MessageStatus.read:
        return strings.messageRead;
      case MessageStatus.recalled:
        return strings.chatPreviewRecalled;
      case MessageStatus.failed:
        return strings.messageFailed;
    }
  }

  Color _statusColor(ThemeData theme) {
    if (outgoingFooterLabel != null) {
      return const Color(0xFF98A1B2);
    }
    return switch (message.status) {
      MessageStatus.failed => theme.colorScheme.error,
      MessageStatus.read => theme.colorScheme.primary,
      MessageStatus.recalled => const Color(0xFF98A1B2),
      _ => const Color(0xFF98A1B2),
    };
  }
}

class _OutgoingStatusRow extends StatelessWidget {
  const _OutgoingStatusRow({
    required this.message,
    required this.onRetryMessage,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.status == MessageStatus.sending)
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF98A1B2),
              ),
            ),
          ),
        if (message.status == MessageStatus.failed)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRetryMessage(message),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: AppIcon(
                AppIconKind.error,
                size: 14,
                color: Color(0xFFF54A45),
              ),
            ),
          ),
      ],
    );
  }
}
