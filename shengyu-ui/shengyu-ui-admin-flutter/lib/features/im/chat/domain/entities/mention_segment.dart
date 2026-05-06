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
}
