import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 通话记录的唯一文案规则。
///
/// 状态码由服务端 ImCallStatusEnum 定义：1 未接听、2 已接通、3 已拒绝、
/// 4 忙线、5 已取消。1v1 记录必须按当前用户是主叫还是被叫展示；否则
/// “对方无应答”和“未接听”会被错误地显示成同一文案。
String callRecordDisplayText({
  required AppLocalizations strings,
  required CallType callType,
  required CallStatus status,
  required int durationSeconds,
  required bool isGroupCall,
  required bool isOutgoing,
  String? callerName,
}) {
  final type = callType == CallType.video
      ? strings.callTypeVideoShort
      : strings.callTypeVoiceShort;
  if (isGroupCall) {
    return _groupCallText(
      strings: strings,
      type: type,
      status: status,
      durationSeconds: durationSeconds,
      callerName: callerName ?? strings.callPeerFallback,
    );
  }
  return switch (status) {
    CallStatus.completed => strings.callRecordCompleted(
      formatCallDuration(durationSeconds),
    ),
    CallStatus.missed =>
      isOutgoing
          ? strings.callRecordOutgoingNoAnswer
          : strings.callRecordIncomingMissed,
    CallStatus.rejected =>
      isOutgoing
          ? strings.callRecordOutgoingRejected
          : strings.callRecordIncomingRejected,
    CallStatus.busy =>
      isOutgoing
          ? strings.callRecordOutgoingBusy
          : strings.callRecordIncomingBusy,
    CallStatus.cancelled =>
      isOutgoing
          ? strings.callRecordOutgoingCancelled
          : strings.callRecordIncomingCancelled,
  };
}

String _groupCallText({
  required AppLocalizations strings,
  required String type,
  required CallStatus status,
  required int durationSeconds,
  required String callerName,
}) {
  final name = callerName.trim().isEmpty
      ? strings.callPeerFallback
      : callerName;
  return switch (status) {
    CallStatus.completed => strings.callRecordGroupCompleted(
      type,
      formatCallDuration(durationSeconds),
    ),
    CallStatus.missed => strings.callRecordGroupMissed(name, type),
    CallStatus.rejected => strings.callRecordGroupRejected(name, type),
    CallStatus.busy => strings.callRecordGroupBusy(name, type),
    CallStatus.cancelled => strings.callRecordGroupCancelled(name, type),
  };
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
