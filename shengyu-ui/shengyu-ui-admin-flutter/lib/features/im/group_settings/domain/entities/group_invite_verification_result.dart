class GroupInviteVerificationResult {
  const GroupInviteVerificationResult({
    required this.valid,
    required this.groupId,
    required this.groupName,
    required this.groupAvatar,
    required this.memberCount,
    required this.needApproval,
    required this.expireTime,
  });

  final bool valid;
  final String groupId;
  final String groupName;
  final String groupAvatar;
  final int memberCount;
  final bool needApproval;
  final String expireTime;
}
