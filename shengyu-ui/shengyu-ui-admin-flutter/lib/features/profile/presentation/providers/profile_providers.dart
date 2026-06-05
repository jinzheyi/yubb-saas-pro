import 'dart:typed_data';

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
/// - 头像上传/删除成功后会被 invalidate，驱动所有依赖此 Provider 的 UI 刷新
final currentUserProfileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (!session.isAuthenticated) {
    return const UserProfile.empty();
  }
  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});

/// 头像上传状态
class AvatarUploadState {
  const AvatarUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
  });

  final bool isUploading;
  final double progress;
  final String? error;

  AvatarUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
  }) {
    return AvatarUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error, // error 独立控制
    );
  }

  static const initial = AvatarUploadState();
}

final avatarUploadStateProvider = StateNotifierProvider<AvatarUploadNotifier, AvatarUploadState>((ref) {
  return AvatarUploadNotifier(ref);
});

class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  AvatarUploadNotifier(this._ref) : super(AvatarUploadState.initial);

  final Ref _ref;

  Future<bool> upload({required String fileName, required Uint8List bytes}) async {
    state = const AvatarUploadState(isUploading: true, progress: 0.0);
    try {
      await _ref.read(profileRepositoryProvider).uploadAvatar(fileName: fileName, bytes: bytes);
      // 上传成功后刷新个人资料
      _ref.invalidate(currentUserProfileProvider);
      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    state = const AvatarUploadState(isUploading: true);
    try {
      await _ref.read(profileRepositoryProvider).deleteAvatar();
      _ref.invalidate(currentUserProfileProvider);
      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const AvatarUploadState();
  }
}
