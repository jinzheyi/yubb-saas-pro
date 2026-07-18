import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/map_thumbnail.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class LocationMessageBubble extends ConsumerWidget {
  const LocationMessageBubble({
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

  Widget _buildMapThumbnail(BuildContext context, Message message) {
    final latitude = message.extra.locationLatitude;
    final longitude = message.extra.locationLongitude;
    
    // 如果没有经纬度，显示默认图标
    if (latitude == null || longitude == null) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: message.isOutgoing
              ? Colors.white.withValues(alpha: 0.16)
              : const Color(0xFFF4F7FC),
        ),
        alignment: Alignment.center,
        child: AppIcon(
          AppIconKind.place,
          size: 34,
          color: message.isOutgoing
              ? Colors.white
              : const Color(0xFFFFA940),
        ),
      );
    }

    // 使用多端适配的地图缩略图组件
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(message.isOutgoing ? 10 : 5),
        bottomRight: Radius.circular(message.isOutgoing ? 5 : 10),
      ),
      child: MapThumbnail(
        latitude: latitude,
        longitude: longitude,
        isOutgoing: message.isOutgoing,
        height: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final locationName = message.extra.locationName?.trim().isNotEmpty == true
        ? message.extra.locationName!.trim()
        : strings.chatLocationUnknownName;
    final address = message.extra.locationAddress?.trim() ?? '';

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
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
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: message.isOutgoing
                    ? const Color(0xFFD2E3FC)
                    : ThemeColors.chatBubbleIncoming(context),
                border: message.isOutgoing
                    ? null
                    : Border.all(color: ThemeColors.divider(context)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: message.isOutgoing
                                ? const Color(0xFF1F2329)
                                : const Color(0xFF202531),
                          ),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address,
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
                      ],
                    ),
                  ),
                  _buildMapThumbnail(context, message),
                ],
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
