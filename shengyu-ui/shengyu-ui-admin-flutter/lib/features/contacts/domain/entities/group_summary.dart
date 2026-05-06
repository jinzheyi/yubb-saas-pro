class GroupSummary {
  const GroupSummary({
    required this.groupId,
    required this.name,
    required this.memberCount,
    this.avatarUrl,
    this.myRole = 0,
    this.pendingJoinRequestCount = 0,
  });

  final String groupId;
  final String name;
  final int memberCount;
  final String? avatarUrl;
  final int myRole;
  final int pendingJoinRequestCount;
}
