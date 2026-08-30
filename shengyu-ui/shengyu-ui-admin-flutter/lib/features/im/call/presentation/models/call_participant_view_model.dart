import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

@immutable
class CallParticipantViewModel {
  const CallParticipantViewModel({
    required this.identity,
    required this.name,
    required this.isLocal,
    required this.cameraEnabled,
    required this.publicationPresent,
    this.avatarUrl,
    this.videoTrack,
  });

  final String identity;
  final String name;
  final String? avatarUrl;
  final bool isLocal;
  final bool cameraEnabled;
  final bool publicationPresent;
  final VideoTrack? videoTrack;

  bool get waitingForTrack =>
      publicationPresent && cameraEnabled && videoTrack == null;
}
