import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/repositories/favorite_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/infrastructure/datasources/favorite_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/infrastructure/repositories/favorite_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/controllers/favorites_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/states/favorites_state.dart';

final favoriteRemoteDataSourceProvider = Provider<FavoriteRemoteDataSource>((
  ref,
) {
  return FavoriteRemoteDataSource(dio: ref.read(dioProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(ref.read(favoriteRemoteDataSourceProvider));
});

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
      return FavoritesController(ref.read(favoriteRepositoryProvider));
    });
