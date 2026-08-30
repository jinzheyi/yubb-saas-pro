import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/direct_video_stage.dart';

void main() {
  const local = CallParticipantViewModel(
    identity: 'local',
    name: '我',
    isLocal: true,
    cameraEnabled: false,
    publicationPresent: false,
  );
  const remote = CallParticipantViewModel(
    identity: 'remote',
    name: '张三',
    isLocal: false,
    cameraEnabled: false,
    publicationPresent: false,
  );

  testWidgets('connected stage keeps local preview below top safe area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            padding: EdgeInsets.only(top: 40),
          ),
          child: const SizedBox(
            width: 390,
            height: 800,
            child: DirectVideoStage(
              local: local,
              remote: remote,
              waitingForRemote: false,
            ),
          ),
        ),
      ),
    );

    final offset = tester.getTopLeft(
      find.byKey(const ValueKey('direct-local-preview')),
    );
    expect(offset.dy, 56);
    expect(
      tester.getSize(find.byKey(const ValueKey('direct-local-preview'))),
      const Size(108, 152),
    );
  });

  testWidgets('outgoing video stage identifies remote waiting state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DirectVideoStage(
          local: local,
          remote: null,
          waitingForRemote: true,
        ),
      ),
    );
    expect(find.text('等待对方接听…'), findsOneWidget);
  });
}
