class GroupSettingsSnapshot {
  const GroupSettingsSnapshot({
    required this.groupId,
    required this.groupName,
    required this.ownerUserId,
    required this.ownerName,
    required this.memberCount,
    required this.notice,
    required this.noticePinned,
    required this.noticeUpdatedAt,
    required this.noDisturb,
    required this.pinned,
    required this.muteAll,
    required this.allowMemberInvite,
    required this.needApproval,
    required this.myNickname,
    required this.pendingJoinRequestCount,
    this.groupMemberStatus,
    this.leftAt,
  });

  final String groupId;
  final String groupName;
  final String ownerUserId;
  final String ownerName;
  final int memberCount;
  final String notice;
  final bool noticePinned;
  final DateTime? noticeUpdatedAt;
  final bool noDisturb;
  final bool pinned;
  final bool muteAll;
  final bool allowMemberInvite;
  final bool needApproval;
  final String myNickname;
  final int pendingJoinRequestCount;
  final int? groupMemberStatus;
  final DateTime? leftAt;
}
