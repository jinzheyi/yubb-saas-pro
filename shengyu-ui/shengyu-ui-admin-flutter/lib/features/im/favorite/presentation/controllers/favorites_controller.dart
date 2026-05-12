import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/repositories/favorite_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/states/favorites_state.dart';

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._favoriteRepository) : super(const FavoritesState());

  final FavoriteRepository _favoriteRepository;

  Future<void> load({bool reset = true}) async {
    if (state.status == FavoritesStatus.loading && !reset) {
      return;
    }
    if (!reset && (!state.hasMore || state.loadingMore)) {
      return;
    }
    final nextPage = reset ? 1 : state.pageNo;
    final normalizedKeyword = state.keyword.trim();
    if (normalizedKeyword.isNotEmpty &&
        (normalizedKeyword.length < 2 || normalizedKeyword.length > 64)) {
      state = state.copyWith(
        status: FavoritesStatus.ready,
        items: reset ? const <FavoriteItem>[] : state.items,
        pageNo: 1,
        hasMore: false,
        totalCount: 0,
        loadingMore: false,
        refreshing: false,
        error: null,
      );
      return;
    }
    state = state.copyWith(
      status: reset ? FavoritesStatus.loading : state.status,
      loadingMore: !reset,
      refreshing: reset && state.items.isNotEmpty,
      error: null,
    );
    try {
      final page = await _favoriteRepository.getFavorites(
        keyword: normalizedKeyword,
        tab: state.tab,
        pageNo: nextPage,
        pageSize: state.pageSize,
      );
      final mergedItems = reset
          ? page.items
          : <FavoriteItem>[...state.items, ...page.items];
      state = state.copyWith(
        status: FavoritesStatus.ready,
        items: mergedItems,
        pageNo: nextPage + 1,
        hasMore: page.hasMore,
        totalCount: page.total,
        loadingMore: false,
        refreshing: false,
        error: null,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: state.items.isEmpty || reset
            ? FavoritesStatus.failed
            : FavoritesStatus.ready,
        loadingMore: false,
        refreshing: false,
        error: AppErrorMapper.map(error, stackTrace),
      );
      return;
    }
  }

  Future<void> refresh() => load(reset: true);

  Future<void> loadMore() => load(reset: false);

  Future<void> updateKeyword(String keyword) async {
    state = state.copyWith(
      keyword: keyword,
      pageNo: 1,
      hasMore: true,
      totalCount: 0,
    );
    await load(reset: true);
  }

  Future<void> updateTab(String tab) async {
    state = state.copyWith(
      tab: tab,
      pageNo: 1,
      hasMore: true,
      totalCount: 0,
    );
    await load(reset: true);
  }

  Future<void> removeFavorite(FavoriteItem item) async {
    await _favoriteRepository.removeFavorite(item.favoriteId);
    final nextItems = state.items
        .where((entry) => entry.favoriteId != item.favoriteId)
        .toList(growable: false);
    state = state.copyWith(
      items: nextItems,
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
      hasMore: nextItems.length < (state.totalCount > 0 ? state.totalCount - 1 : 0),
    );
  }
}
