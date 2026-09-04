import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class CallVideoTile extends StatelessWidget {
  const CallVideoTile({
    super.key,
    required this.participant,
    this.showName = true,
    this.fit = VideoViewFit.cover,
  });

  final CallParticipantViewModel participant;
  final bool showName;
  final VideoViewFit fit;

  @override
  Widget build(BuildContext context) {
    final track = participant.videoTrack;
    return ColoredBox(
      color: const Color(0xFF141416),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (track != null && participant.cameraEnabled)
            VideoTrackRenderer(track, fit: fit)
          else
            _placeholder(context),
          if (showName)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 38,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
                    child: Text(
                      participant.isLocal
                          ? AppLocalizations.of(context).callMe
                          : participant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    if (participant.waitingForTrack) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).callVideoConnecting,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            name: participant.name,
            avatarUrl: participant.avatarUrl,
            seed: participant.identity,
            size: 72,
            borderRadius: 36,
            fontSize: 26,
          ),
          const SizedBox(height: 10),
          const Icon(Icons.videocam_off, color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}
