import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/states/group_settings_state.dart';

class GroupMembersState {
  const GroupMembersState({
    this.groupName = '',
    this.status = GroupMembersStatus.initial,
    this.keyword = '',
    this.members = const <GroupMemberPreviewItem>[],
    this.currentUserId = '',
    this.currentUserRoleCode = 0,
    this.selectedMemberIds = const <String>{},
    this.groupMemberStatus,
    this.error,
  });

  final String groupName;
  final GroupMembersStatus status;
  final String keyword;
  final List<GroupMemberPreviewItem> members;
  final String currentUserId;
  final int currentUserRoleCode;
  final Set<String> selectedMemberIds;
  final int? groupMemberStatus;
  final AppError? error;

  /// 用户是否已离群（被踢/退出/解散）
  bool get hasLeftGroup => groupMemberStatus != null && groupMemberStatus != 0;

  /// 当前用户是否在成员列表中（用于判断是否已不在群内）
  bool get isInMemberList => members.any((m) => m.id == currentUserId);

  List<GroupMemberPreviewItem> get visibleMembers {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) {
      return members;
    }
    return members
        .where(
          (member) =>
              member.name.contains(trimmedKeyword) ||
              (member.deptName?.contains(trimmedKeyword) ?? false),
        )
        .toList();
  }

  bool isSelected(String memberId) => selectedMemberIds.contains(memberId);

  GroupMembersState copyWith({
    String? groupName,
    GroupMembersStatus? status,
    String? keyword,
    List<GroupMemberPreviewItem>? members,
    String? currentUserId,
    int? currentUserRoleCode,
    Set<String>? selectedMemberIds,
    int? groupMemberStatus,
    AppError? error,
  }) {
    return GroupMembersState(
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      members: members ?? this.members,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserRoleCode: currentUserRoleCode ?? this.currentUserRoleCode,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      groupMemberStatus: groupMemberStatus ?? this.groupMemberStatus,
      error: error,
    );
  }
}

enum GroupMembersStatus { initial, loading, ready, failed }
