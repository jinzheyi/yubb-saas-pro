import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/native_call_ui_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native round trip preserves display metadata and group role', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final gateway = NativeCallUiGateway();
    const args = CallLaunchArgs(
      callSessionId: 'call-1',
      chatId: 'chat-1',
      callType: CallType.video,
      entryMode: CallEntryMode.incoming,
      fromUserId: '1',
      title: '旧标题',
      conversationTitle: '项目群',
      callerName: '张三',
      callerAvatarUrl: 'https://example.com/a.png',
      callerId: '1',
      isGroupOwner: false,
      isGroupCall: true,
      groupId: 'group-1',
      inviteeIds: ['2', '3'],
    );

    final decoded = gateway.decodeArgs(gateway.encodeArgs(args));

    expect(decoded, isNotNull);
    expect(decoded!.conversationTitle, '项目群');
    expect(decoded.callerName, '张三');
    expect(decoded.callerAvatarUrl, 'https://example.com/a.png');
    expect(decoded.callerId, '1');
    expect(decoded.isGroupOwner, isFalse);
    expect(decoded.inviteeIds, ['2', '3']);
    await gateway.dispose();
  });
}
