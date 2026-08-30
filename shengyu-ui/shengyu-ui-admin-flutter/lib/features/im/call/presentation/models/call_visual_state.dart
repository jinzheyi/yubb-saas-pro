import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/livekit_call_controller.dart';

enum CallVisualPhase {
  incoming,
  accepting,
  dialing,
  waitingRemote,
  restoring,
  connected,
  reconnecting,
  ending,
  failed,
}

@immutable
class CallVisualState {
  const CallVisualState({
    required this.phase,
    required this.displayName,
    required this.statusText,
    required this.avatarUrl,
    required this.elapsedText,
    required this.endText,
    required this.isGroup,
    required this.isVideo,
    required this.participantCount,
  });

  final CallVisualPhase phase;
  final String displayName;
  final String statusText;
  final String? avatarUrl;
  final String elapsedText;
  final String endText;
  final bool isGroup;
  final bool isVideo;
  final int participantCount;
}

class CallVisualStateResolver {
  const CallVisualStateResolver._();

  static CallVisualState resolve({
    required CallLaunchArgs args,
    required bool accepted,
    required bool accepting,
    required bool closing,
    required bool connected,
    required bool reconnecting,
    required bool hasRemoteParticipant,
    required bool hasLocalParticipant,
    required bool shouldClose,
    required int elapsedSeconds,
    required int remoteParticipantCount,
    CallEndDisplayReason? endReason,
    String? failureText,
  }) {
    final phase = _phase(
      args: args,
      accepted: accepted,
      accepting: accepting,
      closing: closing,
      connected: connected,
      reconnecting: reconnecting,
      hasRemoteParticipant: hasRemoteParticipant,
      shouldClose: shouldClose,
      failureText: failureText,
    );
    final count = (hasLocalParticipant ? 1 : 0) + remoteParticipantCount;
    final elapsed = formatCallDuration(elapsedSeconds);
    final name = _displayName(args);
    return CallVisualState(
      phase: phase,
      displayName: name,
      statusText: _status(
        phase: phase,
        args: args,
        elapsed: elapsed,
        participantCount: count,
      ),
      avatarUrl: _avatarUrl(args),
      elapsedText: elapsed,
      endText: callEndDisplayText(endReason, isGroup: args.isGroupCall),
      isGroup: args.isGroupCall,
      isVideo: args.callType == CallType.video,
      participantCount: count,
    );
  }

  static CallVisualPhase _phase({
    required CallLaunchArgs args,
    required bool accepted,
    required bool accepting,
    required bool closing,
    required bool connected,
    required bool reconnecting,
    required bool hasRemoteParticipant,
    required bool shouldClose,
    required String? failureText,
  }) {
    if (closing || shouldClose) return CallVisualPhase.ending;
    if (failureText != null && failureText.isNotEmpty) {
      return CallVisualPhase.failed;
    }
    if (reconnecting) return CallVisualPhase.reconnecting;
    if (accepting || (args.acceptedFromNative && !connected)) {
      return CallVisualPhase.accepting;
    }
    if (args.entryMode == CallEntryMode.incoming && !accepted) {
      return CallVisualPhase.incoming;
    }
    if (args.entryMode == CallEntryMode.restore && !connected) {
      return CallVisualPhase.restoring;
    }
    if (connected && hasRemoteParticipant) return CallVisualPhase.connected;
    if (connected) return CallVisualPhase.waitingRemote;
    return CallVisualPhase.dialing;
  }

  static String _status({
    required CallVisualPhase phase,
    required CallLaunchArgs args,
    required String elapsed,
    required int participantCount,
  }) {
    return switch (phase) {
      CallVisualPhase.incoming =>
        args.isGroupCall
            ? '${args.callerName ?? '成员'}邀请你加入群${args.callType == CallType.video ? '视频' : '语音'}通话'
            : '邀请你${args.callType == CallType.video ? '视频' : '语音'}通话',
      CallVisualPhase.accepting => '正在接通…',
      CallVisualPhase.dialing => '正在呼叫…',
      CallVisualPhase.waitingRemote => args.isGroupCall ? '等待成员加入…' : '等待对方接听…',
      CallVisualPhase.restoring => '正在恢复通话…',
      CallVisualPhase.connected =>
        args.isGroupCall ? '$participantCount 人通话中 · $elapsed' : elapsed,
      CallVisualPhase.reconnecting => '网络不稳定，正在恢复…',
      CallVisualPhase.ending || CallVisualPhase.failed => '',
    };
  }

  static String _displayName(CallLaunchArgs args) {
    final fallback = args.callType == CallType.video ? '视频通话' : '语音通话';
    if (args.isGroupCall) {
      return _firstNonEmpty([
        args.conversationTitle,
        args.entryMode == CallEntryMode.incoming ? args.callerName : args.title,
        '群$fallback',
      ]);
    }
    return _firstNonEmpty([
      args.conversationTitle,
      args.callerName,
      args.title,
      fallback,
    ]);
  }

  static String? _avatarUrl(CallLaunchArgs args) {
    if (args.entryMode == CallEntryMode.outgoing) return args.peerAvatarUrl;
    return args.callerAvatarUrl ?? args.peerAvatarUrl;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '通话';
  }
}

String formatCallDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remaining = safe % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remaining.toString().padLeft(2, '0')}';
}

String callEndDisplayText(
  CallEndDisplayReason? reason, {
  required bool isGroup,
}) {
  return switch (reason) {
    CallEndDisplayReason.localCancel => '已取消',
    CallEndDisplayReason.localReject => '已拒绝',
    CallEndDisplayReason.localHangup => '通话已结束',
    CallEndDisplayReason.remoteReject => '对方已拒绝',
    CallEndDisplayReason.remoteCancel => '对方已取消',
    CallEndDisplayReason.remoteHangup => '对方已挂断',
    CallEndDisplayReason.noAnswer => '对方无应答',
    CallEndDisplayReason.otherDeviceAccepted => '通话已在其他设备接听',
    CallEndDisplayReason.networkLost => '网络连接中断，通话已结束',
    CallEndDisplayReason.maxDuration => '通话时长已达上限，通话已结束',
    CallEndDisplayReason.groupEnded => '群通话已结束',
    CallEndDisplayReason.restoreFailed => '恢复通话失败',
    CallEndDisplayReason.acceptFailed => '接听失败',
    CallEndDisplayReason.microphonePermissionDenied => '需要麦克风权限才能通话',
    CallEndDisplayReason.mediaPermissionDenied => '需要摄像头和麦克风权限才能视频通话',
    CallEndDisplayReason.failed => '通话连接失败，请稍后重试',
    null => isGroup ? '群通话已结束' : '通话已结束',
  };
}

String callDestructiveLabel({
  required CallLaunchArgs args,
  required CallVisualPhase phase,
}) {
  if (args.isGroupCall) {
    return args.isGroupOwner == true ? '结束通话' : '退出通话';
  }
  if (phase == CallVisualPhase.restoring) return '退出通话';
  if (phase == CallVisualPhase.dialing ||
      phase == CallVisualPhase.waitingRemote) {
    return '取消';
  }
  return '挂断';
}
