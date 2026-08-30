import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/livekit_call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_visual_state.dart';

void main() {
  const incoming = CallLaunchArgs(
    callSessionId: 'call-1',
    chatId: 'chat-1',
    callType: CallType.audio,
    entryMode: CallEntryMode.incoming,
    callerName: '张三',
  );

  CallVisualState resolve({
    CallLaunchArgs args = incoming,
    bool accepted = false,
    bool accepting = false,
    bool closing = false,
    bool connected = false,
    bool reconnecting = false,
    bool remote = false,
    bool shouldClose = false,
    int seconds = 0,
    CallEndDisplayReason? endReason,
  }) => CallVisualStateResolver.resolve(
    args: args,
    accepted: accepted,
    accepting: accepting,
    closing: closing,
    connected: connected,
    reconnecting: reconnecting,
    hasRemoteParticipant: remote,
    hasLocalParticipant: connected,
    shouldClose: shouldClose,
    elapsedSeconds: seconds,
    remoteParticipantCount: remote ? 1 : 0,
    endReason: endReason,
  );

  test('incoming and accepting phases use user-facing copy', () {
    expect(resolve().phase, CallVisualPhase.incoming);
    expect(resolve().statusText, '邀请你语音通话');
    expect(resolve(accepting: true).phase, CallVisualPhase.accepting);
    expect(resolve(accepting: true).statusText, '正在接通…');
  });

  test('restore has priority before ordinary dialing', () {
    final state = resolve(
      args: incoming.copyWith(entryMode: CallEntryMode.restore),
      accepted: true,
    );
    expect(state.phase, CallVisualPhase.restoring);
    expect(state.statusText, '正在恢复通话…');
  });

  test('connected group count and duration use room facts', () {
    final state = CallVisualStateResolver.resolve(
      args: CallLaunchArgs.outgoing(
        callSessionId: '',
        chatId: 'chat',
        callType: CallType.video,
        title: '项目群',
        isGroupCall: true,
        groupId: 'group',
      ),
      accepted: true,
      accepting: false,
      closing: false,
      connected: true,
      reconnecting: false,
      hasRemoteParticipant: true,
      hasLocalParticipant: true,
      shouldClose: false,
      elapsedSeconds: 66,
      remoteParticipantCount: 2,
    );
    expect(state.phase, CallVisualPhase.connected);
    expect(state.statusText, '3 人通话中 · 01:06');
  });

  test('ending reason maps MAX_DURATION without exposing enum', () {
    final state = resolve(
      shouldClose: true,
      endReason: CallEndDisplayReason.maxDuration,
    );
    expect(state.phase, CallVisualPhase.ending);
    expect(state.endText, '通话时长已达上限，通话已结束');
  });

  test('duration formats over one hour', () {
    expect(formatCallDuration(3661), '01:01:01');
  });

  test('group incoming without group title falls back to caller identity', () {
    final state = resolve(
      args: const CallLaunchArgs(
        callSessionId: 'call-group',
        chatId: 'chat-group',
        callType: CallType.video,
        entryMode: CallEntryMode.incoming,
        callerName: '张三',
        isGroupCall: true,
      ),
    );
    expect(state.displayName, '张三');
    expect(state.statusText, '张三邀请你加入群视频通话');
  });

  test('restored group owner keeps end-call label', () {
    const owner = CallLaunchArgs(
      callSessionId: 'call-owner',
      chatId: 'chat-owner',
      callType: CallType.audio,
      entryMode: CallEntryMode.restore,
      isGroupCall: true,
      isGroupOwner: true,
    );
    expect(
      callDestructiveLabel(args: owner, phase: CallVisualPhase.restoring),
      '结束通话',
    );
    expect(
      callDestructiveLabel(
        args: owner.copyWith(isGroupOwner: false),
        phase: CallVisualPhase.restoring,
      ),
      '退出通话',
    );
  });

  test('permission failures use controlled user-facing copy', () {
    expect(
      callEndDisplayText(
        CallEndDisplayReason.microphonePermissionDenied,
        isGroup: false,
      ),
      '需要麦克风权限才能通话',
    );
    expect(
      callEndDisplayText(
        CallEndDisplayReason.mediaPermissionDenied,
        isGroup: false,
      ),
      '需要摄像头和麦克风权限才能视频通话',
    );
  });
}
