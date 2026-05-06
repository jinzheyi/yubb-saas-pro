class GroupMember {
  const GroupMember({
    required this.userId,
    required this.userName,
    required this.nickname,
    required this.role,
    this.avatarUrl,
    this.deptName,
    this.joinTime,
    this.muteEndTime,
    this.isMuted = false,
  });

  final String userId;
  final String userName;
  final String nickname;
  final int role;
  final String? avatarUrl;
  final String? deptName;
  final String? joinTime;
  final DateTime? muteEndTime;
  final bool isMuted;
}
