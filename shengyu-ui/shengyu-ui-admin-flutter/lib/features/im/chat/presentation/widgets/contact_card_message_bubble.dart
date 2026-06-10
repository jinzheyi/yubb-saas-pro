import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 名片消息气泡 — 统一发送/接收样式
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
    final strings = ref.watch(appStringsProvider);
    final isOutgoing = message.isOutgoing;

    // 名片数据
    final displayName = message.extra.contactDisplayName?.trim().isNotEmpty ==
            true
        ? message.extra.contactDisplayName!.trim()
        : strings.chatContactCardUnknownName;
    final subtitle = message.extra.contactPostName?.trim().isNotEmpty == true
        ? message.extra.contactPostName!.trim()
        : (message.extra.contactDepartmentName?.trim() ?? '');
    final avatarUrl = message.extra.contactAvatar?.trim() ?? '';
    final contactUserId = message.extra.contactUserId?.trim() ?? '';

    // 气泡颜色
    final cardBgColor = isOutgoing
        ? const Color(0xFFD2E3FC)
        : ThemeColors.chatBubbleIncoming(context);
    final cardTextColor = isOutgoing ? const Color(0xFF1F2329) : ThemeColors.chatBubbleIncomingText(context);
    final cardSubtitleColor = isOutgoing
        ? const Color(0xFF6B7380)
        : ThemeColors.textSecondary(context);

    return Column(
      crossAxisAlignment:
          isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              constraints: const BoxConstraints(maxWidth: 260, minWidth: 200),
              decoration: BoxDecoration(
                color: cardBgColor,
                border: isOutgoing
                    ? null
                    : Border.all(color: ThemeColors.divider(context)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isOutgoing ? 12 : 3),
                  bottomRight: Radius.circular(isOutgoing ? 3 : 12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像：固定 48x48，有头像URL时显示图片，无头像时显示文字头像
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AppAvatar(
                        name: displayName,
                        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                        seed: contactUserId.isNotEmpty ? contactUserId : null,
                        size: 48,
                        borderRadius: 10,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 文字内容
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
                              fontWeight: FontWeight.w600,
                              color: cardTextColor,
                              height: 1.3,
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
                                height: 1.3,
                                color: cardSubtitleColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_rounded,
                                size: 14,
                                color: cardSubtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                strings.chatContactCardLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cardSubtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
}
