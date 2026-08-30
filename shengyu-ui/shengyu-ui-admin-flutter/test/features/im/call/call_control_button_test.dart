import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_control_button.dart';

void main() {
  testWidgets('renders label and exposes button semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallControlButton(
            icon: Icons.mic,
            label: '麦克风已开',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('麦克风已开'), findsOneWidget);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.label),
      contains('麦克风已开'),
    );
    semantics.dispose();
  });

  testWidgets('loading prevents repeated taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CallControlButton(
          icon: Icons.call,
          label: '接听',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(CallControlButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
