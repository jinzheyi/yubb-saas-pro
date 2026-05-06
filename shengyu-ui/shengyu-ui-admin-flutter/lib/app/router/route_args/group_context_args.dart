class GroupContextArgs {
  const GroupContextArgs({
    required this.groupId,
    this.groupName,
    this.mode = GroupMembersPageMode.view,
  });

  final String groupId;
  final String? groupName;
  final GroupMembersPageMode mode;

  bool get isViewMode => mode == GroupMembersPageMode.view;

  bool get isRemoveMode => mode == GroupMembersPageMode.remove;

  bool get isTransferMode => mode == GroupMembersPageMode.transfer;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GroupContextArgs &&
        other.groupId == groupId &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(groupId, mode);
}

enum GroupMembersPageMode { view, remove, transfer }
