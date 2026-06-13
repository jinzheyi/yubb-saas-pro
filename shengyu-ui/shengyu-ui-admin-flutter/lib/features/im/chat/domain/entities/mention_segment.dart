class MentionSegment {
  const MentionSegment({
    required this.userId,
    required this.nickname,
    required this.startIndex,
    required this.endIndex,
  });

  final String userId;
  final String nickname;
  final int startIndex;
  final int endIndex;

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'startIndex': startIndex,
      'endIndex': endIndex,
    };
  }

  factory MentionSegment.fromJson(Map<String, dynamic> json) {
    return MentionSegment(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      startIndex: (json['startIndex'] as num?)?.toInt() ?? 0,
      endIndex: (json['endIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
