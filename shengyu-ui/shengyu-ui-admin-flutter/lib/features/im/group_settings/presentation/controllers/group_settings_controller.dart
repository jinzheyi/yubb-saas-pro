import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class GroupSettingsController extends StateNotifier<GroupSettingsState> {
  GroupSettingsController(this._repository, this._args, this._currentUserId)
    : super(
        GroupSettingsState(
          groupName: _args.groupName?.trim().isNotEmpty == true
              ? _args.groupName!
              : '',
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

  void _setStateIfActive(GroupSettingsState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }

  Future<void> load() async {
    _setStateIfActive(
      state.copyWith(status: GroupSettingsStatus.loading, error: null),
    );
    try {
      final snapshot = await _repository.getGroupSettings(_args.groupId);
      final members = await _repository.getGroupMembers(_args.groupId);
      final conversationSettings = await _repository
          .getGroupConversationSettings(_args.groupId);
      GroupMember? currentMember;
      for (final member in members) {
        if (member.userId == _currentUserId) {
          currentMember = member;
          break;
        }
      }
      final hasMembers = members.isNotEmpty;
      final membershipBlocked =
          hasMembers &&
          _currentUserId.trim().isNotEmpty &&
          currentMember == null;
      final currentUserRoleCode = currentMember?.role ?? 0;
      var pendingRequestCount = snapshot.pendingJoinRequestCount;
      if (currentUserRoleCode == 1 || currentUserRoleCode == 2) {
        pendingRequestCount = await _repository.getPendingJoinRequestCount(
          _args.groupId,
        );
      }
      _setStateIfActive(state.copyWith(
        status: GroupSettingsStatus.ready,
        chatId: conversationSettings.chatId,
        groupName: snapshot.groupName,
        notice: snapshot.notice,
        noticePinned: snapshot.noticePinned,
        noticeUpdatedAt: snapshot.noticeUpdatedAt,
        members: members.take(8).map((member) {
          return GroupMemberPreviewItem(
            id: member.userId,
            name: member.nickname.isNotEmpty
                ? member.nickname
                : member.userName,
            roleCode: member.role,
            colorValue: _memberColorValue(member.userId),
            avatarUrl: member.avatarUrl,
            deptName: member.deptName,
            joinTime: member.joinTime,
            muteEndTime: member.muteEndTime,
            isMuted: member.isMuted,
          );
        }).toList(),
        memberCount: snapshot.memberCount,
        ownerUserId: snapshot.ownerUserId,
        ownerName: snapshot.ownerName,
        noDisturb: conversationSettings.noDisturb,
        pinned: conversationSettings.pinned,
        muteAll: snapshot.muteAll,
        allowMemberInvite: snapshot.allowMemberInvite,
        needApproval: snapshot.needApproval,
        myNickname: snapshot.myNickname,
        membershipBlocked: membershipBlocked,
        currentUserRoleCode: currentUserRoleCode,
        currentUserMuteEndTime: currentMember?.muteEndTime,
        pendingRequestCount: pendingRequestCount,
      ));
    } catch (error, stackTrace) {
      _setStateIfActive(state.copyWith(
        status: GroupSettingsStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      ));
    }
  }

  Future<void> updateNoDisturb(bool value) async {
    if (state.chatId.isEmpty) {
      return;
    }
    final previous = state.noDisturb;
    _setStateIfActive(state.copyWith(noDisturb: value));
    try {
      await _repository.updateNoDisturb(chatId: state.chatId, noDisturb: value);
    } catch (_) {
      _setStateIfActive(state.copyWith(noDisturb: previous));
    }
  }

  Future<void> updatePinned(bool value) async {
    if (state.chatId.isEmpty) {
      return;
    }
    final previous = state.pinned;
    _setStateIfActive(state.copyWith(pinned: value));
    try {
      await _repository.updatePinned(chatId: state.chatId, pinned: value);
    } catch (_) {
      _setStateIfActive(state.copyWith(pinned: previous));
    }
  }

  Future<void> clearChatHistory() async {
    if (state.chatId.isEmpty) {
      return;
    }
    await _repository.clearChatHistory(chatId: state.chatId);
  }

  Future<void> dissolveGroup() {
    return _repository.dissolveGroup(groupId: _args.groupId);
  }

  Future<void> quitGroup() {
    return _repository.quitGroup(groupId: _args.groupId);
  }

  Future<void> updateMuteAll(bool value) async {
    final previous = state.muteAll;
    if (previous == value) {
      return;
    }
    _setStateIfActive(state.copyWith(muteAll: value));
    try {
      await _repository.updateMuteAll(groupId: _args.groupId, muted: value);
    } catch (_) {
      _setStateIfActive(state.copyWith(muteAll: previous));
      rethrow;
    }
  }

  Future<void> updateAllowMemberInvite(bool value) async {
    final previous = state.allowMemberInvite;
    if (previous == value) {
      return;
    }
    _setStateIfActive(state.copyWith(allowMemberInvite: value));
    try {
      await _repository.updateGroupManageOptions(
        groupId: _args.groupId,
        allowMemberInvite: value,
      );
    } catch (_) {
      _setStateIfActive(state.copyWith(allowMemberInvite: previous));
    }
  }

  Future<void> updateNeedApproval(bool value) async {
    final previous = state.needApproval;
    if (previous == value) {
      return;
    }
    _setStateIfActive(state.copyWith(needApproval: value));
    try {
      await _repository.updateGroupManageOptions(
        groupId: _args.groupId,
        needApproval: value,
      );
    } catch (_) {
      _setStateIfActive(state.copyWith(needApproval: previous));
    }
  }

  Future<void> updateGroupName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final previous = state.groupName;
    if (previous == trimmed) {
      return;
    }
    _setStateIfActive(state.copyWith(groupName: trimmed));
    try {
      await _repository.updateGroupName(groupId: _args.groupId, groupName: trimmed);
    } catch (_) {
      _setStateIfActive(state.copyWith(groupName: previous));
      rethrow;
    }
  }

  void updateNotice(
    String value, {
    bool? noticePinned,
    DateTime? noticeUpdatedAt,
    String? ownerName,
  }) {
    _setStateIfActive(state.copyWith(
      notice: value,
      noticePinned: noticePinned,
      noticeUpdatedAt: noticeUpdatedAt,
      ownerName: ownerName,
    ));
  }

  Future<void> updateMyNickname(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final previous = state.myNickname;
    if (previous == trimmed) {
      return;
    }
    _setStateIfActive(state.copyWith(myNickname: trimmed));
    try {
      await _repository.updateMyNickname(groupId: _args.groupId, nickname: trimmed);
    } catch (_) {
      _setStateIfActive(state.copyWith(myNickname: previous));
      rethrow;
    }
  }

  void markMembershipRestored() {
    _setStateIfActive(state.copyWith(membershipBlocked: false));
  }

  void applyRealtimeMuteAll(bool muted) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(muteAll: muted);
  }

  void applyRealtimeCurrentUserMute(DateTime? muteEndTime) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(currentUserMuteEndTime: muteEndTime);
  }

  Future<void> reloadMembersOnly() async {
    if (_disposed || state.status != GroupSettingsStatus.ready) {
      return;
    }
    try {
      _setStateIfActive(state.copyWith(status: GroupSettingsStatus.loading));
      final members = await _repository.getGroupMembers(_args.groupId);
      final previewItems = members.take(8).map((member) {
        return GroupMemberPreviewItem(
          id: member.userId,
          name: member.nickname.isNotEmpty
              ? member.nickname
              : member.userName,
          roleCode: member.role,
          colorValue: _memberColorValue(member.userId),
          avatarUrl: member.avatarUrl,
          deptName: member.deptName,
          joinTime: member.joinTime,
          muteEndTime: member.muteEndTime,
          isMuted: member.isMuted,
        );
      }).toList();
      _setStateIfActive(state.copyWith(
        status: GroupSettingsStatus.ready,
        members: previewItems,
        memberCount: members.length,
      ));
    } catch (error, stackTrace) {
      _setStateIfActive(state.copyWith(
        status: GroupSettingsStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      ));
    }
  }

  void applyRealtimeMembers(List<GroupMemberPreviewItem> members) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      members: members.take(8).toList(growable: false),
      memberCount: members.length,
    );
  }

  void applyRealtimeMemberCount(int count) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(memberCount: count);
  }

  int _memberColorValue(String seed) {
    return getUserAvatarColor(seed).toARGB32();
  }
}
