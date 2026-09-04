import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/livekit_call_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

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
    required AppLocalizations strings,
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
    final name = _displayName(args, strings);
    return CallVisualState(
      phase: phase,
      displayName: name,
      statusText: _status(
        phase: phase,
        strings: strings,
        args: args,
        elapsed: elapsed,
        participantCount: count,
      ),
      avatarUrl: _avatarUrl(args),
      elapsedText: elapsed,
      endText: callEndDisplayText(
        strings,
        endReason,
        isGroup: args.isGroupCall,
      ),
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
    required AppLocalizations strings,
    required CallVisualPhase phase,
    required CallLaunchArgs args,
    required String elapsed,
    required int participantCount,
  }) {
    return switch (phase) {
      CallVisualPhase.incoming =>
        args.isGroupCall
            ? strings.callIncomingGroupInvite(
                args.callerName ?? strings.callMemberFallback,
                args.callType == CallType.video
                    ? strings.callTypeVideoShort
                    : strings.callTypeVoiceShort,
              )
            : strings.callIncomingInvite(
                args.callType == CallType.video
                    ? strings.callTypeVideoShort
                    : strings.callTypeVoiceShort,
              ),
      CallVisualPhase.accepting => strings.callAccepting,
      CallVisualPhase.dialing => strings.callDialing,
      CallVisualPhase.waitingRemote =>
        args.isGroupCall
            ? strings.callWaitingForMembers
            : strings.callWaitingForAnswer,
      CallVisualPhase.restoring => strings.callRestoring,
      CallVisualPhase.connected =>
        args.isGroupCall
            ? strings.callGroupParticipants(participantCount, elapsed)
            : elapsed,
      CallVisualPhase.reconnecting => strings.callNetworkRestoring,
      CallVisualPhase.ending || CallVisualPhase.failed => '',
    };
  }

  static String _displayName(CallLaunchArgs args, AppLocalizations strings) {
    final fallback = args.callType == CallType.video
        ? strings.callVideo
        : strings.callVoice;
    if (args.isGroupCall) {
      return _firstNonEmpty(strings, [
        args.conversationTitle,
        args.entryMode == CallEntryMode.incoming ? args.callerName : args.title,
        strings.callGroupFallback(fallback),
      ]);
    }
    return _firstNonEmpty(strings, [
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

  static String _firstNonEmpty(AppLocalizations strings, List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return strings.callGenericFallback;
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
  AppLocalizations strings,
  CallEndDisplayReason? reason, {
  required bool isGroup,
}) {
  return switch (reason) {
    CallEndDisplayReason.localCancel => strings.callCancelled,
    CallEndDisplayReason.localReject => strings.callRejected,
    CallEndDisplayReason.localHangup => strings.callEnded,
    CallEndDisplayReason.remoteReject => strings.callRecordOutgoingRejected,
    CallEndDisplayReason.remoteCancel => strings.callRecordIncomingCancelled,
    CallEndDisplayReason.remoteHangup => strings.callRemoteHangup,
    CallEndDisplayReason.noAnswer => strings.callRecordOutgoingNoAnswer,
    CallEndDisplayReason.otherDeviceAccepted => strings.callOtherDeviceAnswered,
    CallEndDisplayReason.networkLost => strings.callNetworkLostEnded,
    CallEndDisplayReason.maxDuration => strings.callMaxDurationEnded,
    CallEndDisplayReason.groupEnded => strings.callEnded,
    CallEndDisplayReason.restoreFailed => strings.callRestoreFailed,
    CallEndDisplayReason.acceptFailed => strings.callAcceptFailed,
    CallEndDisplayReason.microphonePermissionDenied =>
      strings.callMicrophonePermissionRequired,
    CallEndDisplayReason.mediaPermissionDenied =>
      strings.callMediaPermissionRequired,
    CallEndDisplayReason.failed => strings.callConnectFailed,
    null => strings.callEnded,
  };
}

String callDestructiveLabel({
  required AppLocalizations strings,
  required CallLaunchArgs args,
  required CallVisualPhase phase,
}) {
  if (args.isGroupCall) {
    return args.isGroupOwner == true
        ? strings.callEndGroup
        : strings.callLeaveGroup;
  }
  if (phase == CallVisualPhase.restoring) return strings.callLeaveGroup;
  if (phase == CallVisualPhase.dialing ||
      phase == CallVisualPhase.waitingRemote) {
    return '取消';
  }
  return '挂断';
}
