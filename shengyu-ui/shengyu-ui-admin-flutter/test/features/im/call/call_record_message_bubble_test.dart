import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_record_message_bubble.dart';

void main() {
  CallRecordMessage message(CallStatus status, {int duration = 0}) =>
      CallRecordMessage(
        callId: 'call',
        callType: CallType.video,
        status: status,
        duration: duration,
        callerId: '1',
        calleeId: '2',
        initiateTime: 0,
      );

  Future<void> pump(
    WidgetTester tester,
    CallStatus status, {
    required bool outgoing,
    int duration = 0,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CallRecordMessageBubble(
          message: message(status, duration: duration),
          isOutgoing: outgoing,
        ),
      ),
    ),
  );

  testWidgets('rejection and cancellation have accurate subjects', (
    tester,
  ) async {
    await pump(tester, CallStatus.rejected, outgoing: true);
    expect(find.text('对方已拒绝'), findsOneWidget);
    await pump(tester, CallStatus.rejected, outgoing: false);
    expect(find.text('已拒绝'), findsOneWidget);
    await pump(tester, CallStatus.cancelled, outgoing: false);
    expect(find.text('对方已取消'), findsOneWidget);
  });

  testWidgets('completed call formats hour duration', (tester) async {
    await pump(tester, CallStatus.completed, outgoing: true, duration: 3661);
    expect(find.text('视频通话时长 01:01:01'), findsOneWidget);
  });

  testWidgets('record without callback has no tap detector', (tester) async {
    await pump(tester, CallStatus.missed, outgoing: false);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
