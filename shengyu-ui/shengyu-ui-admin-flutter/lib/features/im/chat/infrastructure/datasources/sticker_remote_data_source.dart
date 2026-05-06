import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_catalog.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/sticker_item_dto.dart';

class StickerRemoteDataSource {
  const StickerRemoteDataSource({required this.dio});

  final Dio dio;

  Future<StickerCatalog> getStickerCatalog() async {
    final response = await dio.get('/system/im/sticker/list');
    final result = ApiResult.fromJson<StickerCatalog>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final recent = (data['recent'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StickerItemDto.fromJson)
            .map((item) => item.toEntity())
            .toList();
        final favorites = (data['favorites'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StickerItemDto.fromJson)
            .map((item) => item.toEntity())
            .toList();
        return StickerCatalog(
          version: (data['version'] as num?)?.toInt() ?? 0,
          recent: recent,
          favorites: favorites,
        );
      },
    );
    return result.requireData();
  }

  Future<StickerItemDto> uploadSticker({
    required String fileId,
    required String url,
    required String name,
    String md5 = '',
    String mimeType = '',
  }) async {
    final response = await dio.post(
      '/system/im/sticker/upload',
      data: {
        'fileId': fileId,
        'url': url,
        'name': name,
        'md5': md5,
        'mimeType': mimeType,
      },
    );
    final result = ApiResult.fromJson<StickerItemDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          StickerItemDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  Future<StickerItemDto> collectSticker({required String messageId}) async {
    final response = await dio.post(
      '/system/im/sticker/collect',
      data: {'messageId': messageId},
    );
    final result = ApiResult.fromJson<StickerItemDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          StickerItemDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  Future<void> removeSticker({required String stickerId}) async {
    await dio.delete(
      '/system/im/sticker/remove',
      queryParameters: {'id': stickerId},
    );
  }

  Future<void> sortSticker({
    required List<({String stickerId, int sortNo})> items,
  }) async {
    await dio.put(
      '/system/im/sticker/sort',
      data: {
        'items': items
            .map((item) => {'stickerId': item.stickerId, 'sortNo': item.sortNo})
            .toList(),
      },
    );
  }

  Future<void> recordRecentUse({required String stickerId}) async {
    await dio.post(
      '/system/im/sticker/recent/use',
      queryParameters: {'stickerId': stickerId},
    );
  }
}
