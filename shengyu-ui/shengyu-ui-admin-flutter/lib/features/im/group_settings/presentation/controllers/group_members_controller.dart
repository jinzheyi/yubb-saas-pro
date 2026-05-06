import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_members_state.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }
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
      final validSelections = state.selectedMemberIds
          .where((memberId) => items.any((item) => item.id == memberId))
          .toSet();
      state = state.copyWith(
        status: GroupMembersStatus.ready,
        members: items,
        currentUserRoleCode: currentUserRoleCode,
        selectedMemberIds: validSelections,
      );
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        status: GroupMembersStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
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
    const colors = <int>[
      0xFF27C38A,
      0xFFFF9AA8,
      0xFFF6D2B3,
      0xFFE97CAB,
      0xFF8FB8F7,
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }
}
