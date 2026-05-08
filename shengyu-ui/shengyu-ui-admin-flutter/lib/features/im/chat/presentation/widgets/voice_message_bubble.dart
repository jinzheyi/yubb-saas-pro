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
    final duration = message.extra.duration ?? 0;
    final durationLabel = _durationLabel(duration);
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
            GestureDetector(
              onLongPressStart: onLongPressMessage == null
                  ? null
                  : (details) =>
                        onLongPressMessage!(message, details.globalPosition),
              child: InkWell(
                onTap: () => onOpenMessage(message),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 72,
                    maxWidth: 238,
                  ),
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
                      bottomLeft: Radius.circular(message.isOutgoing ? 12 : 5),
                      bottomRight: Radius.circular(message.isOutgoing ? 5 : 12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: message.isOutgoing
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final height in bars)
                              Container(
                                width: 2,
                                height: height.toDouble(),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
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
                                  value: _progressValue(duration),
                                  backgroundColor: progressTrackColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor,
                                  ),
                                ),
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
                      if (isPaused) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: message.isOutgoing
                                ? const Color(0x260F4AA3)
                                : const Color(0x1F1677FF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '暂停',
                            style: TextStyle(
                              fontSize: 11,
                              color: message.isOutgoing
                                  ? const Color(0xFF0F4AA3)
                                  : const Color(0xFF1677FF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!message.isOutgoing && unread) ...[
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

  String _durationLabel(int duration) {
    return '${duration <= 0 ? 1 : duration}s';
  }

  double? _progressValue(int duration) {
    final totalMs = playbackDurationMs > 0
        ? playbackDurationMs
        : (duration <= 0 ? 1 : duration) * 1000;
    if (totalMs <= 0) {
      return null;
    }
    final currentMs = playbackProgressMs.clamp(0, totalMs);
    return currentMs / totalMs;
  }

  List<int> _waveHeights() => const [6, 10, 14, 10, 6];

  String? _statusLabelText() {
    if (isPaused) {
      return '继续播放';
    }
    if (isPlaying) {
      return '播放中';
    }
    if (message.status == MessageStatus.sending) {
      return '发送中';
    }
    if (message.status == MessageStatus.failed) {
      return '发送失败';
    }
    return null;
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
