import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_detail.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_page_result.dart';

abstract class FavoriteRepository {
  Future<FavoritePageResult> getFavorites({
    String keyword = '',
    String tab = 'default',
    int pageNo = 1,
    int pageSize = 20,
  });

  Future<void> removeFavorite(String favoriteId);

  Future<FavoriteDetail> getFavoriteDetail(String favoriteId);

  Future<void> resendFavorite({
    required String favoriteId,
    required String targetChatId,
  });
}
