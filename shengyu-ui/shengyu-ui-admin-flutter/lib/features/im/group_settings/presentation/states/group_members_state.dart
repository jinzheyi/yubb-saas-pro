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
    this.error,
  });

  final String groupName;
  final GroupMembersStatus status;
  final String keyword;
  final List<GroupMemberPreviewItem> members;
  final String currentUserId;
  final int currentUserRoleCode;
  final Set<String> selectedMemberIds;
  final AppError? error;

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
      error: error,
    );
  }
}

enum GroupMembersStatus { initial, loading, ready, failed }
