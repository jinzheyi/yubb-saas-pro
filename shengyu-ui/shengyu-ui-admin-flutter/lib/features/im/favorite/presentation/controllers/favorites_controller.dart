import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/repositories/favorite_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/states/favorites_state.dart';

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._favoriteRepository) : super(const FavoritesState());

  final FavoriteRepository _favoriteRepository;

  Future<void> load() async {
    state = state.copyWith(status: FavoritesStatus.loading, error: null);
    try {
      final items = await _favoriteRepository.getFavorites(
        keyword: state.keyword,
        tab: state.tab,
      );
      state = state.copyWith(status: FavoritesStatus.ready, items: items);
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: FavoritesStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> updateKeyword(String keyword) async {
    state = state.copyWith(keyword: keyword);
    await load();
  }

  Future<void> updateTab(String tab) async {
    state = state.copyWith(tab: tab);
    await load();
  }

  Future<void> removeFavorite(FavoriteItem item) async {
    await _favoriteRepository.removeFavorite(item.favoriteId);
    state = state.copyWith(
      items: state.items
          .where((entry) => entry.favoriteId != item.favoriteId)
          .toList(),
    );
  }
}
