import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_catalog.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';

abstract class StickerRepository {
  Future<StickerCatalog> getStickerCatalog();

  Future<StickerItem> uploadSticker({
    required String fileId,
    required String url,
    required String name,
    String md5 = '',
    String mimeType = '',
  });

  Future<StickerItem> collectSticker({required String messageId});

  Future<void> removeSticker({required String stickerId});

  Future<void> sortSticker({
    required List<({String stickerId, int sortNo})> items,
  });

  Future<void> recordRecentUse({required String stickerId});
}
