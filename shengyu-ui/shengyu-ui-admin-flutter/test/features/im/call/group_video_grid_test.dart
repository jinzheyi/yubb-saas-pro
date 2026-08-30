import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/group_video_grid.dart';

void main() {
  CallParticipantViewModel participant(int index) => CallParticipantViewModel(
    identity: '$index',
    name: '成员$index',
    isLocal: index == 0,
    cameraEnabled: false,
    publicationPresent: false,
  );

  for (final count in <int>[1, 2, 3, 4, 5, 9]) {
    testWidgets('renders stable $count participant layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 600,
              child: GroupVideoGrid(
                participants: List.generate(count, participant),
              ),
            ),
          ),
        ),
      );
      expect(find.text('我'), findsOneWidget);
      if (count > 1) expect(find.text('成员1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('five participants keep fixed three-row grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 600,
          child: GroupVideoGrid(participants: List.generate(5, participant)),
        ),
      ),
    );

    final first = tester.getSize(
      find.byKey(const ValueKey('group-video-cell-0')),
    );
    expect(first.height, closeTo(200, 1));
    expect(find.byKey(const ValueKey('group-video-empty-8')), findsOneWidget);
  });
}
