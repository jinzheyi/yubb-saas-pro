import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 消息状态页脚组件（发送中/已发送/已读/失败等）
///
/// 用于所有消息气泡组件的底部状态显示，
/// 统一处理发送状态和重试逻辑，避免代码重复。
class MessageStatusFooter extends StatelessWidget {
  const MessageStatusFooter({
    super.key,
    required this.message,
    required this.onRetryMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context) {
    if (!showOutgoingStatusFooter || !message.isOutgoing) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _OutgoingStatusRow(
          message: message,
          onRetryMessage: onRetryMessage,
        ),
        const SizedBox(height: 4),
        _StatusLabel(
          message: message,
          onOpenReadReceipt: onOpenReadReceipt,
          enableReadReceiptEntry: enableReadReceiptEntry,
          outgoingFooterLabel: outgoingFooterLabel,
        ),
      ],
    );
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

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.message,
    required this.onOpenReadReceipt,
    required this.enableReadReceiptEntry,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return GestureDetector(
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
    );
  }

  String _statusLabel(AppLocalizations strings) {
    return switch (message.status) {
      MessageStatus.sending => strings.messageSending,
      MessageStatus.sent => strings.messageSent,
      MessageStatus.delivered => strings.messageDelivered,
      MessageStatus.read => strings.messageRead,
      MessageStatus.recalled => strings.chatPreviewRecalled,
      MessageStatus.failed => strings.messageFailed,
    };
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
