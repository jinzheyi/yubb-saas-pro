import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';

enum FavoritesStatus { initial, loading, ready, failed }

class FavoritesState {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.items = const <FavoriteItem>[],
    this.keyword = '',
    this.tab = 'default',
    this.error,
  });

  final FavoritesStatus status;
  final List<FavoriteItem> items;
  final String keyword;
  final String tab;
  final AppError? error;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteItem>? items,
    String? keyword,
    String? tab,
    AppError? error,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      items: items ?? this.items,
      keyword: keyword ?? this.keyword,
      tab: tab ?? this.tab,
      error: error,
    );
  }
}
