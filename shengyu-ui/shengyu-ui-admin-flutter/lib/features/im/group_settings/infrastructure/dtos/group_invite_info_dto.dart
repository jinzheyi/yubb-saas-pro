class GroupInviteInfoDto {
  const GroupInviteInfoDto({
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

  factory GroupInviteInfoDto.fromJson(Map<String, dynamic> json) {
    final expireAt =
        _parseDateTime(json['expireAt']) ?? _parseDateTime(json['expireTime']);
    return GroupInviteInfoDto(
      groupId: '${json['groupId'] ?? json['id'] ?? ''}',
      inviteCode: '${json['inviteCode'] ?? json['code'] ?? ''}',
      expireAt: expireAt,
      needApproval: _parseBool(json['needApproval']),
      qrCodeUrl:
          json['qrCodeUrl']?.toString() ??
          json['qrUrl']?.toString() ??
          json['qrImageUrl']?.toString(),
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw > 0 ? DateTime.fromMillisecondsSinceEpoch(raw) : null;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final millis = int.tryParse(text);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final text = raw?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1';
  }
}
