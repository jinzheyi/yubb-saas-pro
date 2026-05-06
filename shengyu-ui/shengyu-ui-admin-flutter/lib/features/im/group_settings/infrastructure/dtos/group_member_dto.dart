class GroupMemberDto {
  const GroupMemberDto({
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

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) {
    final rawMuteEndTime =
        json['muteEndTime'] ??
        json['mutedEndTime'] ??
        json['muteUntil'] ??
        json['mutedUntil'];
    final muteEndTime = _parseMuteEndTime(rawMuteEndTime);
    return GroupMemberDto(
      userId: '${json['userId'] ?? json['memberUserId'] ?? ''}',
      userName: '${json['userName'] ?? json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? json['userNickname'] ?? ''}',
      role: (json['role'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      deptName: json['deptName']?.toString(),
      joinTime:
          json['joinTime']?.toString() ??
          json['joinedAt']?.toString() ??
          json['joinAt']?.toString() ??
          json['createTime']?.toString(),
      muteEndTime: muteEndTime,
      isMuted:
          json['muted'] == true ||
          json['isMuted'] == true ||
          (muteEndTime != null && muteEndTime.isAfter(DateTime.now().toUtc())),
    );
  }
}

DateTime? _parseMuteEndTime(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is num) {
    final value = raw.toInt();
    if (value <= 0) {
      return null;
    }
    final milliseconds = value > 100000000000 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
  final text = raw.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return parsed.toUtc();
  }
  final numeric = int.tryParse(text);
  if (numeric == null || numeric <= 0) {
    return null;
  }
  final milliseconds = numeric > 100000000000 ? numeric : numeric * 1000;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}
