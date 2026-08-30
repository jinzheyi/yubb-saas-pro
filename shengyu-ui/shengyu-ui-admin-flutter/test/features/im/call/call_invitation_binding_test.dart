import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';

void main() {
  test('direct invite preserves nested caller profile', () {
    final args = callLaunchArgsFromPayload(
      raw: <String, Object?>{
        'callSessionId': 'call-1',
        'chatId': 'chat-1',
        'callType': 'video',
        'callerProfile': <String, Object?>{
          'userId': '11',
          'displayName': '张三',
          'avatarUrl': 'https://example.com/avatar.png',
        },
      },
      type: 'call.invite',
      currentUserId: '22',
    );

    expect(args.entryMode, CallEntryMode.incoming);
    expect(args.callerId, '11');
    expect(args.callerName, '张三');
    expect(args.callerAvatarUrl, 'https://example.com/avatar.png');
    expect(args.conversationTitle, '张三');
  });

  test('group invite reads local conversation title without blocking', () {
    final args = callLaunchArgsFromPayload(
      raw: <String, Object?>{
        'callId': 'call-2',
        'chatId': 'chat-2',
        'groupId': 'group-2',
        'callerId': '11',
        'callerName': '李四',
        'callerAvatar': 'avatar',
        'inviteeIds': <String>['22', '33'],
      },
      type: 'call.group_invite',
      currentUserId: '22',
      conversationTitleByChatId: (chatId) => chatId == 'chat-2' ? '项目群' : null,
    );

    expect(args.isGroupCall, isTrue);
    expect(args.conversationTitle, '项目群');
    expect(args.callerName, '李四');
    expect(args.isGroupOwner, isFalse);
    expect(args.inviteeIds, <String>['22', '33']);
  });

  test('recovered group owner is derived from caller id', () {
    final args = callLaunchArgsFromPayload(
      raw: <String, Object?>{
        'callSessionId': 'call-3',
        'chatId': 'chat-3',
        'groupId': 'group-3',
        'callerId': '11',
        'callerName': '群主',
        '_recoveredState': 'connected',
      },
      type: 'call.group_invite',
      currentUserId: '11',
    );

    expect(args.entryMode, CallEntryMode.restore);
    expect(args.isGroupOwner, isTrue);
  });
}
