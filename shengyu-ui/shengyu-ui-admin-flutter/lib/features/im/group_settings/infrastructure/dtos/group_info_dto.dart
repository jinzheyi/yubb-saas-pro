class GroupInfoDto {
  const GroupInfoDto({
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
  final int? groupMemberStatus;
  final DateTime? leftAt;

  factory GroupInfoDto.fromJson(Map<String, dynamic> json) {
    return GroupInfoDto(
      groupId: '${json['id'] ?? json['groupId'] ?? ''}',
      groupName: '${json['groupName'] ?? json['name'] ?? ''}',
      ownerUserId: '${json['ownerUserId'] ?? json['ownerId'] ?? ''}',
      ownerName:
          '${json['ownerName'] ?? json['groupOwnerName'] ?? json['ownerNickname'] ?? ''}',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      notice: '${json['notice'] ?? ''}',
      noticePinned: json['noticePinned'] == true,
      noticeUpdatedAt: _parseDateTime(
        json['noticeUpdateTime'] ?? json['updateTime'],
      ),
      noDisturb: json['noDisturb'] == true,
      pinned: json['pinned'] == true,
      muteAll: json['muteAll'] == true,
      allowMemberInvite: json['allowMemberInvite'] != false,
      needApproval: json['needApproval'] == true,
      myNickname: '${json['myNickname'] ?? json['nickname'] ?? ''}',
      groupMemberStatus: _parseInt(json['groupMemberStatus'] ?? json['memberStatus']),
      leftAt: _parseDateTime(json['leftAt']),
    );
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is num) {
      final raw = value.toInt();
      if (raw <= 0) {
        return null;
      }
      final millis = raw > 9999999999 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final asInt = int.tryParse(text);
    if (asInt != null) {
      final millis = asInt > 9999999999 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.tryParse(text);
  }
}
