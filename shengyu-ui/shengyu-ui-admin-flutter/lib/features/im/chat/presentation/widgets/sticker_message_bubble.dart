import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/chat_image_provider_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/utils/message_media_content_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/message_status_footer.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class StickerMessageBubble extends StatelessWidget {
  const StickerMessageBubble({
    super.key,
    required this.message,
    required this.onRetryMessage,
    this.onLongPressMessage,
    this.onOpenReadReceipt,
    this.enableReadReceiptEntry = false,
    this.showOutgoingStatusFooter = true,
    this.outgoingFooterLabel,
  });

  final Message message;
  final ValueChanged<Message> onRetryMessage;
  final void Function(Message, Offset globalPosition)? onLongPressMessage;
  final ValueChanged<Message>? onOpenReadReceipt;
  final bool enableReadReceiptEntry;
  final bool showOutgoingStatusFooter;
  final String? outgoingFooterLabel;

  @override
  Widget build(BuildContext context) {
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
        ? resolveChatImageProvider(localPath: localPath)
        : (emojiAssets.isNotEmpty
              ? AssetImage(emojiAssets.first) as ImageProvider
              : (!isEmoji
                    ? resolveChatImageProvider(remoteUrl: url.trim())
                    : null));

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
                        color: ThemeColors.surfaceDim(context),
                        borderRadius: BorderRadius.all(
                          Radius.circular(isEmoji ? 0 : 4),
                        ),
                      ),
                      child: Center(
                        child: AppIcon(
                          AppIconKind.smile,
                          size: 28,
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(isEmoji ? 0 : 4),
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
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
