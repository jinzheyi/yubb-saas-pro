import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';

class StickerCatalog {
  const StickerCatalog({
    required this.version,
    this.recent = const <StickerItem>[],
    this.favorites = const <StickerItem>[],
  });

  final int version;
  final List<StickerItem> recent;
  final List<StickerItem> favorites;
}
