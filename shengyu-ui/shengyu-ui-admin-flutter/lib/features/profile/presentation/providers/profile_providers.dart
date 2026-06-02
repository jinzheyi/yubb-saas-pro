import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/repositories/profile_repository.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/datasources/profile_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/repositories/profile_repository_impl.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(dio: ref.read(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.read(profileRemoteDataSourceProvider));
});

/// 当前登录用户的个人资料 Provider
///
/// 关键设计：
/// - 显式依赖 authSessionProvider，确保用户切换时自动重新请求
/// - 当 authSessionProvider 变化时，此 Provider 会自动重新计算
/// - 未登录时（userId 为空）返回空 UserProfile，避免 401 错误
final currentUserProfileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (!session.isAuthenticated) {
    return const UserProfile.empty();
  }
  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});
