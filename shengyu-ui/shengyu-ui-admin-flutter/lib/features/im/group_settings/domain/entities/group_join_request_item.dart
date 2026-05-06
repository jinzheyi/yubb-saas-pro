class GroupJoinRequestItem {
  const GroupJoinRequestItem({
    required this.id,
    required this.applicantUserId,
    required this.applicantNickname,
    this.applicantAvatar,
    required this.status,
    this.createTime,
    this.handledTime,
    this.rejectReason,
  });

  final String id;
  final String applicantUserId;
  final String applicantNickname;
  final String? applicantAvatar;
  final int status;
  final DateTime? createTime;
  final DateTime? handledTime;
  final String? rejectReason;
}
