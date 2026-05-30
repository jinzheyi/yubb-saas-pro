class GroupInviteInfo {
  GroupInviteInfo({
    required this.groupId,
    required this.inviteCode,
    this.expireAt,
    this.needApproval = false,
    this.qrCodeUrl,
    this.qrCodeContent,
  });

  final String groupId;
  final String inviteCode;
  final DateTime? expireAt;
  final bool needApproval;
  final String? qrCodeUrl;
  final String? qrCodeContent;

  bool get isPermanent =>
      expireAt == null || expireAt!.year >= 9999;

  String get effectiveQrCodeContent {
    if (qrCodeContent != null && qrCodeContent!.isNotEmpty) {
      return qrCodeContent!;
    }
    return 'shengyu://group/join?code=$inviteCode&groupId=$groupId';
  }
}
