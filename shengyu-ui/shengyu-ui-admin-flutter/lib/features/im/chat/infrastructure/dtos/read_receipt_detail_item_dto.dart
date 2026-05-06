class ReadReceiptDetailItemDto {
  const ReadReceiptDetailItemDto({
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.readTime,
  });

  final String userId;
  final String userName;
  final String avatar;
  final DateTime? readTime;

  factory ReadReceiptDetailItemDto.fromJson(Map<String, dynamic> json) {
    return ReadReceiptDetailItemDto(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      userName:
          json['userNickname']?.toString() ??
          json['userName']?.toString() ??
          json['nickname']?.toString() ??
          json['name']?.toString() ??
          '',
      avatar:
          json['userAvatar']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar']?.toString() ??
          '',
      readTime: _parseDateTime(
        json['readTime'] ?? json['updateTime'] ?? json['createTime'],
      ),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    final numeric = int.tryParse(raw);
    if (numeric != null) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    return DateTime.tryParse(raw);
  }
}
