import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_detail.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/repositories/favorite_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/infrastructure/datasources/favorite_remote_data_source.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  const FavoriteRepositoryImpl(this._remoteDataSource);

  final FavoriteRemoteDataSource _remoteDataSource;

  @override
  Future<List<FavoriteItem>> getFavorites({
    String keyword = '',
    String tab = 'default',
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final items = await _remoteDataSource.getFavorites(
      keyword: keyword,
      tab: tab,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items
        .map(
          (item) => FavoriteItem(
            favoriteId: item.favoriteId,
            messageId: item.messageId,
            chatId: item.chatId,
            conversationType: item.conversationType,
            title: item.title,
            summary: item.summary,
            senderName: item.senderName,
            messageType: item.messageType,
            status: item.status,
            createdAt: item.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> removeFavorite(String favoriteId) {
    return _remoteDataSource.removeFavorite(favoriteId);
  }

  @override
  Future<FavoriteDetail> getFavoriteDetail(String favoriteId) async {
    final detail = await _remoteDataSource.getFavoriteDetail(favoriteId);
    return FavoriteDetail(
      favoriteId: detail.favoriteId,
      messageType: detail.messageType,
      messagePreview: detail.messagePreview,
      messageContent: detail.messageContent,
      messageExtra: detail.messageExtra,
      messageSnapshot: detail.messageSnapshot,
      sendTime: detail.sendTime,
      favoriteTime: detail.favoriteTime,
    );
  }

  @override
  Future<void> resendFavorite({
    required String favoriteId,
    required String targetChatId,
  }) {
    return _remoteDataSource.resendFavorite(
      favoriteId: favoriteId,
      targetChatId: targetChatId,
    );
  }
}
