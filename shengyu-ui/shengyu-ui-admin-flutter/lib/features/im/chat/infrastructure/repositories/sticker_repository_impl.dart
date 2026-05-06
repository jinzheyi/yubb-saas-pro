import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_catalog.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/sticker_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/sticker_remote_data_source.dart';

class StickerRepositoryImpl implements StickerRepository {
  StickerRepositoryImpl(this._remoteDataSource);

  final StickerRemoteDataSource _remoteDataSource;

  @override
  Future<StickerCatalog> getStickerCatalog() {
    return _remoteDataSource.getStickerCatalog();
  }

  @override
  Future<StickerItem> uploadSticker({
    required String fileId,
    required String url,
    required String name,
    String md5 = '',
    String mimeType = '',
  }) async {
    final dto = await _remoteDataSource.uploadSticker(
      fileId: fileId,
      url: url,
      name: name,
      md5: md5,
      mimeType: mimeType,
    );
    return dto.toEntity();
  }

  @override
  Future<StickerItem> collectSticker({required String messageId}) async {
    final dto = await _remoteDataSource.collectSticker(messageId: messageId);
    return dto.toEntity();
  }

  @override
  Future<void> removeSticker({required String stickerId}) {
    return _remoteDataSource.removeSticker(stickerId: stickerId);
  }

  @override
  Future<void> sortSticker({
    required List<({String stickerId, int sortNo})> items,
  }) {
    return _remoteDataSource.sortSticker(items: items);
  }

  @override
  Future<void> recordRecentUse({required String stickerId}) {
    return _remoteDataSource.recordRecentUse(stickerId: stickerId);
  }
}
