import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class StickerMessageBubble extends StatelessWidget {
  const StickerMessageBubble({
    super.key,
    required this.message,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isEmoji = message.type == MessageType.emoji;
    final normalizedEmojiToken = isEmoji
        ? ChatEmojiCatalog.normalizeTokenContent(message.content)
        : null;
    final localPath = message.extra.localPath;
    final url = message.extra.thumbnailUrl?.trim().isNotEmpty == true
        ? message.extra.thumbnailUrl!.trim()
        : (message.extra.fileUrl?.trim().isNotEmpty == true
              ? message.extra.fileUrl!.trim()
              : extractMediaUrlFromRawContent(message.content));
    final emojiAssets = normalizedEmojiToken != null
        ? ChatEmojiCatalog.candidateAssetsFor(normalizedEmojiToken)
        : <String>[
            ...?(() {
              final asset = ChatEmojiCatalog.assetForAssetLikePath(url);
              return asset == null ? null : <String>[asset];
            })(),
          ];
    final imageProvider = localPath != null && localPath.isNotEmpty
        ? FileImage(File(localPath)) as ImageProvider
        : (emojiAssets.isNotEmpty
              ? AssetImage(emojiAssets.first) as ImageProvider
              : (!isEmoji && url.trim().isNotEmpty ? NetworkImage(url) : null));

    return Column(
      crossAxisAlignment: message.isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: onLongPressMessage == null
              ? null
              : (details) =>
                    onLongPressMessage!(message, details.globalPosition),
          child: InkWell(
            onTap: null,
            borderRadius: BorderRadius.circular(isEmoji ? 0 : 4),
            child: SizedBox(
              width: isEmoji ? 100 : 120,
              height: isEmoji ? 100 : 120,
              child: imageProvider == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4FA),
                        borderRadius: BorderRadius.all(
                          Radius.circular(isEmoji ? 0 : 4),
                        ),
                      ),
                      child: const Center(
                        child: AppIcon(
                          AppIconKind.smile,
                          size: 28,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(isEmoji ? 0 : 4),
                      child: Image(
                        image: imageProvider,
                        fit: isEmoji ? BoxFit.contain : BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        if (message.isOutgoing && showOutgoingStatusFooter) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap:
                enableReadReceiptEntry &&
                    message.status != MessageStatus.sending &&
                    message.status != MessageStatus.failed
                ? () => onOpenReadReceipt?.call(message)
                : null,
            child: Text(
              outgoingFooterLabel ?? _statusLabel(strings),
              style: const TextStyle(fontSize: 10, color: Color(0xFF98A1B2)),
            ),
          ),
        ],
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
}
