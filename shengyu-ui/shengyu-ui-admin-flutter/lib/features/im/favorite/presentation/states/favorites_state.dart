import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';

enum FavoritesStatus { initial, loading, ready, failed }

class FavoritesState {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.items = const <FavoriteItem>[],
    this.keyword = '',
    this.tab = 'default',
    this.pageNo = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.totalCount = 0,
    this.loadingMore = false,
    this.refreshing = false,
    this.error,
  });

  final FavoritesStatus status;
  final List<FavoriteItem> items;
  final String keyword;
  final String tab;
  final int pageNo;
  final int pageSize;
  final bool hasMore;
  final int totalCount;
  final bool loadingMore;
  final bool refreshing;
  final AppError? error;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteItem>? items,
    String? keyword,
    String? tab,
    int? pageNo,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? loadingMore,
    bool? refreshing,
    AppError? error,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      items: items ?? this.items,
      keyword: keyword ?? this.keyword,
      tab: tab ?? this.tab,
      pageNo: pageNo ?? this.pageNo,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      loadingMore: loadingMore ?? this.loadingMore,
      refreshing: refreshing ?? this.refreshing,
      error: error,
    );
  }
}
