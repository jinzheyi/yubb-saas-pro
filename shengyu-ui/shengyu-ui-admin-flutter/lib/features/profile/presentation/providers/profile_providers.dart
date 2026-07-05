import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/repositories/profile_repository.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/datasources/profile_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';

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
      // 1. 获取旧头像 URL（用于后续清理缓存）
      final oldProfile = _ref.read(currentUserProfileProvider).valueOrNull;
      final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

      // 2. 上传新头像
      await _ref.read(profileRepositoryProvider).uploadAvatar(fileName: fileName, bytes: bytes);
      
      // 3. 清理旧头像的磁盘缓存
      if (oldAvatarUrl.isNotEmpty) {
        unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
      }

      // 4. 清理内存缓存
      PaintingBinding.instance.imageCache.clear();

      // 5. 刷新当前用户资料
      _ref.invalidate(currentUserProfileProvider);

      // 6. 刷新会话列表
      _ref.invalidate(conversationListControllerProvider);

      // 7. 刷新技术通讯录
      _ref.invalidate(contactsPageControllerProvider);

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
      // 1. 获取旧头像 URL
      final oldProfile = _ref.read(currentUserProfileProvider).valueOrNull;
      final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

      // 2. 删除头像
      await _ref.read(profileRepositoryProvider).deleteAvatar();
      
      // 3. 清理旧头像的磁盘缓存
      if (oldAvatarUrl.isNotEmpty) {
        unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
      }

      // 4. 清理内存缓存
      PaintingBinding.instance.imageCache.clear();

      // 5. 刷新所有相关 Provider
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(conversationListControllerProvider);
      _ref.invalidate(contactsPageControllerProvider);

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
