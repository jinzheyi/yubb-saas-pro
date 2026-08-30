import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_type_selection_sheet.dart';

void main() {
  testWidgets('shared sheet returns selected call type', (tester) async {
    CallType? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await CallTypeSelectionSheet.show(
                context,
                displayName: '张三',
                voiceLabel: '语音通话',
                videoLabel: '视频通话',
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('与「张三」通话'), findsOneWidget);
    await tester.tap(find.text('视频通话'));
    await tester.pumpAndSettle();
    expect(selected, CallType.video);
  });
}
