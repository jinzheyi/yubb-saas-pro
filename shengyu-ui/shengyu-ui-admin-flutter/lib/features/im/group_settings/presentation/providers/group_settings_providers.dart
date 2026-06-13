import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/controllers/group_members_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/controllers/group_settings_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_members_state.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/datasources/group_settings_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/repositories/group_settings_repository_impl.dart';

class GroupJoinRequestSignal {
  const GroupJoinRequestSignal({
    required this.groupId,
    required this.action,
    required this.payload,
    required this.token,
  });

  final String groupId;
  final String action;
  final Map<String, Object?> payload;
  final int token;
}

final groupSettingsRemoteDataSourceProvider =
    Provider<GroupSettingsRemoteDataSource>((ref) {
      final currentUserId = ref.read(authSessionProvider).userId;
      return GroupSettingsRemoteDataSource(
        dio: ref.read(dioProvider),
        currentUserId: currentUserId,
      );
    });

final groupSettingsRepositoryProvider = Provider<GroupSettingsRepository>((
  ref,
) {
  return GroupSettingsRepositoryImpl(
    ref.read(groupSettingsRemoteDataSourceProvider),
  );
});

final groupSettingsControllerProvider = StateNotifierProvider.autoDispose
    .family<GroupSettingsController, GroupSettingsState, GroupContextArgs>((
      ref,
      args,
    ) {
      return GroupSettingsController(
        ref.read(groupSettingsRepositoryProvider),
        args,
        ref.read(authSessionProvider).userId,
      );
    });

final groupMembersControllerProvider = StateNotifierProvider.autoDispose
    .family<GroupMembersController, GroupMembersState, GroupContextArgs>((
      ref,
      args,
    ) {
      return GroupMembersController(
        ref.read(groupSettingsRepositoryProvider),
        args,
        ref.read(authSessionProvider).userId,
      );
    });

final groupMembersFutureProvider = FutureProvider.family((ref, String groupId) {
  // 优化：直接通过 Repository 获取，依赖 Repository 层的缓存和并发去重机制
  // 避免独立于 groupSettingsController 重复请求
  return ref.read(groupSettingsRepositoryProvider).getGroupMembers(groupId);
});

final groupJoinRequestSignalProvider =
    StateProvider<GroupJoinRequestSignal?>((ref) => null);
