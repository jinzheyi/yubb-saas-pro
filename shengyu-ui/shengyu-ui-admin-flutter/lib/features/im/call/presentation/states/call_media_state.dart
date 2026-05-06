enum RtcConnectionStatus {
  idle,
  preparing,
  joining,
  connected,
  reconnecting,
  disconnected,
}

class CallMediaState {
  const CallMediaState({
    this.microphoneEnabled = true,
    this.cameraEnabled = false,
    this.speakerEnabled = true,
    this.frontCamera = true,
    this.localTrackReady = false,
    this.remoteTrackReady = false,
    this.rtcConnectionStatus = RtcConnectionStatus.idle,
  });

  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool speakerEnabled;
  final bool frontCamera;
  final bool localTrackReady;
  final bool remoteTrackReady;
  final RtcConnectionStatus rtcConnectionStatus;

  CallMediaState copyWith({
    bool? microphoneEnabled,
    bool? cameraEnabled,
    bool? speakerEnabled,
    bool? frontCamera,
    bool? localTrackReady,
    bool? remoteTrackReady,
    RtcConnectionStatus? rtcConnectionStatus,
  }) {
    return CallMediaState(
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      localTrackReady: localTrackReady ?? this.localTrackReady,
      remoteTrackReady: remoteTrackReady ?? this.remoteTrackReady,
      rtcConnectionStatus: rtcConnectionStatus ?? this.rtcConnectionStatus,
    );
  }
}
