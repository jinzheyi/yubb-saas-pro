import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_members_state.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class GroupMembersController extends StateNotifier<GroupMembersState> {
  GroupMembersController(this._repository, this._args, this._currentUserId)
    : super(
        GroupMembersState(
          groupName: _args.groupName?.trim().isNotEmpty == true
              ? _args.groupName!
              : '',
          currentUserId: _currentUserId,
        ),
      ) {
    load();
  }

  final GroupSettingsRepository _repository;
  final GroupContextArgs _args;
  final String _currentUserId;
  bool _disposed = false;
  Completer<void>? _loadCompleter;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }
    // 优化：如果正在加载中，返回现有 Completer，避免并发重复请求
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }
    // 优化：如果已有数据且非错误状态，不重复加载（防抖）
    if (state.status == GroupMembersStatus.ready && state.members.isNotEmpty) {
      return;
    }

    _loadCompleter = Completer<void>();
    state = state.copyWith(status: GroupMembersStatus.loading, error: null);
    try {
      final members = await _repository.getGroupMembers(_args.groupId);
      if (_disposed) {
        return;
      }
      var currentUserRoleCode = state.currentUserRoleCode;
      final items = members.map((member) {
        if (member.userId == _currentUserId) {
          currentUserRoleCode = member.role;
        }
        return GroupMemberPreviewItem(
          id: member.userId,
          name: member.nickname.isNotEmpty ? member.nickname : member.userName,
          roleCode: member.role,
          colorValue: _memberColorValue(member.userId),
          avatarUrl: member.avatarUrl,
          deptName: member.deptName,
          joinTime: member.joinTime,
          muteEndTime: member.muteEndTime,
          isMuted: member.isMuted,
        );
      }).toList();

      // 从群设置状态中获取 groupMemberStatus
      int? groupMemberStatus;
      try {
        final settingsState = await _repository.getGroupSettings(_args.groupId);
        groupMemberStatus = settingsState.groupMemberStatus;
      } catch (_) {
        // 忽略，使用默认值
      }

      final validSelections = state.selectedMemberIds
          .where((memberId) => items.any((item) => item.id == memberId))
          .toSet();
      state = state.copyWith(
        status: GroupMembersStatus.ready,
        members: items,
        currentUserRoleCode: currentUserRoleCode,
        selectedMemberIds: validSelections,
        groupMemberStatus: groupMemberStatus,
      );
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        status: GroupMembersStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    } finally {
      final completer = _loadCompleter;
      _loadCompleter = null;
      completer?.complete();
    }
  }

  void updateKeyword(String value) {
    state = state.copyWith(keyword: value);
  }

  void toggleSelection(String memberId) {
    final next = state.selectedMemberIds.toSet();
    if (!next.add(memberId)) {
      next.remove(memberId);
    }
    state = state.copyWith(selectedMemberIds: next);
  }

  void clearSelection() {
    if (state.selectedMemberIds.isEmpty) {
      return;
    }
    state = state.copyWith(selectedMemberIds: <String>{});
  }

  Future<void> removeMembers(List<String> memberIds) async {
    for (final memberId in memberIds) {
      await _repository.removeGroupMember(
        groupId: _args.groupId,
        memberUserId: memberId,
      );
    }
    await load();
  }

  Future<void> transferOwner(String memberId) async {
    await _repository.transferGroupOwner(
      groupId: _args.groupId,
      newOwnerId: memberId,
    );
    await load();
  }

  Future<void> setMemberRole({
    required String memberId,
    required int role,
  }) async {
    await _repository.setGroupMemberRole(
      groupId: _args.groupId,
      memberUserId: memberId,
      role: role,
    );
    await load();
  }

  Future<void> setMemberMuted({
    required String memberId,
    required bool muted,
  }) async {
    await _repository.setGroupMemberMuted(
      groupId: _args.groupId,
      memberUserId: memberId,
      muted: muted,
    );
    await load();
  }

  int _memberColorValue(String seed) {
    return getUserAvatarColor(seed).toARGB32();
  }
}
