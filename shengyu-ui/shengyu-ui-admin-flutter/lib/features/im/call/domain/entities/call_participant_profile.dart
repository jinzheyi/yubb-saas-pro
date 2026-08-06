class CallParticipantProfile {
  const CallParticipantProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.cameraEnabled = true,
    this.microphoneEnabled = true,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool cameraEnabled;
  final bool microphoneEnabled;

  CallParticipantProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    bool? cameraEnabled,
    bool? microphoneEnabled,
  }) {
    return CallParticipantProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
    );
  }
}
