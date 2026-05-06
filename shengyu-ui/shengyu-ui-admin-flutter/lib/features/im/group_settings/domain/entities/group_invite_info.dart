class GroupInviteInfo {
  const GroupInviteInfo({
    required this.groupId,
    required this.inviteCode,
    this.expireAt,
    this.needApproval = false,
    this.qrCodeUrl,
  });

  final String groupId;
  final String inviteCode;
  final DateTime? expireAt;
  final bool needApproval;
  final String? qrCodeUrl;
}
