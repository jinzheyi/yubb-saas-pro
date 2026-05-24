class GroupJoinRequestItemDto {
  const GroupJoinRequestItemDto({
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

  factory GroupJoinRequestItemDto.fromJson(Map<String, dynamic> json) {
    return GroupJoinRequestItemDto(
      id: '${json['id'] ?? ''}',
      applicantUserId: '${json['applicantUserId'] ?? json['userId'] ?? ''}',
      applicantNickname:
          '${json['applicantNickname'] ?? json['nickname'] ?? ''}',
      applicantAvatar:
          json['applicantAvatar']?.toString() ??
          json['userAvatar']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar']?.toString(),
      status: _parseInt(json['status']) ?? 1,
      createTime: _parseDateTime(json['createTime'] ?? json['applyTime']),
      handledTime: _parseDateTime(
        json['handledTime'] ?? json['updateTime'] ?? json['auditTime'],
      ),
      rejectReason: json['rejectReason']?.toString(),
    );
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static DateTime? _parseDateTime(Object? raw) {
    final millis = _parseInt(raw);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }
}
