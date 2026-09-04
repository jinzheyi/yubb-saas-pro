import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_video_tile.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class DirectVideoStage extends StatelessWidget {
  const DirectVideoStage({
    super.key,
    required this.local,
    required this.remote,
    required this.waitingForRemote,
  });

  final CallParticipantViewModel? local;
  final CallParticipantViewModel? remote;
  final bool waitingForRemote;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final main = remote ?? local;
    if (main == null) {
      return ColoredBox(
        color: Color(0xFF0B0B0D),
        child: Center(
          child: Text(
            AppLocalizations.of(context).callStartingCamera,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CallVideoTile(participant: main, showName: false),
        if (waitingForRemote)
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  AppLocalizations.of(context).callWaitingForAnswer,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        if (remote != null && local != null)
          Positioned(
            key: const ValueKey('direct-local-preview'),
            right: 16,
            top: safeTop + 16,
            width: 108,
            height: 152,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x66FFFFFF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CallVideoTile(participant: local!, showName: false),
              ),
            ),
          ),
      ],
    );
  }
}
