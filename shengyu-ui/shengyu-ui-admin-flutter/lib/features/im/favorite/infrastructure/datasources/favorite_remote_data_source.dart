import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/infrastructure/dtos/favorite_detail_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/infrastructure/dtos/favorite_item_dto.dart';

class FavoriteRemoteDataSource {
  const FavoriteRemoteDataSource({required this.dio});

  final Dio dio;

  Future<List<FavoriteItemDto>> getFavorites({
    String keyword = '',
    String tab = 'default',
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final normalizedKeyword = keyword.trim();
    final response = await dio.get(
      normalizedKeyword.isEmpty
          ? '/system/im/favorite/list'
          : '/system/im/favorite/search',
      queryParameters: {
        if (normalizedKeyword.isNotEmpty) 'keyword': normalizedKeyword,
        if (normalizedKeyword.isNotEmpty) 'tab': tab,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
    );
    final result = ApiResult.fromJson<List<FavoriteItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapPageList(raw, FavoriteItemDto.fromJson),
    );
    return result.requireData();
  }

  Future<void> removeFavorite(String favoriteId) async {
    await dio.delete(
      '/system/im/favorite/remove',
      queryParameters: {'favoriteId': favoriteId},
    );
  }

  Future<FavoriteDetailDto> getFavoriteDetail(String favoriteId) async {
    final response = await dio.get(
      '/system/im/favorite/detail',
      queryParameters: {'favoriteId': favoriteId},
    );
    final result = ApiResult.fromJson<FavoriteDetailDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return FavoriteDetailDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }

  Future<void> resendFavorite({
    required String favoriteId,
    required String targetChatId,
  }) async {
    await dio.post(
      '/system/im/favorite/resend',
      data: {'favoriteId': favoriteId, 'targetChatId': targetChatId},
    );
  }

  List<T> _mapPageList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final data = raw as Map<String, dynamic>? ?? const {};
    final items = data['list'] as List<dynamic>? ?? const [];
    return items.whereType<Map<String, dynamic>>().map(parser).toList();
  }
}
