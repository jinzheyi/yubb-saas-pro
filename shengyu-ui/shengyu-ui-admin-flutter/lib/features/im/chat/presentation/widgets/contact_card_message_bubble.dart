import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ContactCardMessageBubble extends ConsumerWidget {
  const ContactCardMessageBubble({
    super.key,
    required this.message,
    required this.onRetryMessage,
    required this.onOpenMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final ValueChanged<Message> onOpenMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final displayName =
        message.extra.contactDisplayName?.trim().isNotEmpty == true
        ? message.extra.contactDisplayName!.trim()
        : strings.chatContactCardUnknownName;
    final subtitle = message.extra.contactPostName?.trim().isNotEmpty == true
        ? message.extra.contactPostName!.trim()
        : (message.extra.contactDepartmentName?.trim() ?? '');

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.isOutgoing)
          _OutgoingStatusRow(message: message, onRetryMessage: onRetryMessage),
        const SizedBox(height: 4),
        GestureDetector(
          onLongPressStart: onLongPressMessage == null
              ? null
              : (details) =>
                    onLongPressMessage!(message, details.globalPosition),
          child: InkWell(
            onTap: () => onOpenMessage(message),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isOutgoing
                    ? const Color(0xFF2F6BFF)
                    : Colors.white,
                border: message.isOutgoing
                    ? null
                    : Border.all(color: const Color(0xFFEFF2F6)),
                boxShadow: message.isOutgoing
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0A162033),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(message.isOutgoing ? 10 : 5),
                  bottomRight: Radius.circular(message.isOutgoing ? 5 : 10),
                ),
              ),
              child: Row(
                children: [
                  ContactsInitialAvatar(
                    name: displayName,
                    color: message.isOutgoing
                        ? Colors.white.withValues(alpha: 0.16)
                        : const Color(0xFF246BFD),
                    avatarUrl: message.extra.contactAvatar,
                    size: 40,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: message.isOutgoing
                                ? Colors.white
                                : const Color(0xFF202531),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: message.isOutgoing
                                  ? const Color(0xFFD7E3FF)
                                  : const Color(0xFF8F96A3),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          strings.chatContactCardLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: message.isOutgoing
                                ? const Color(0xFFD7E3FF)
                                : const Color(0xFF8F96A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
