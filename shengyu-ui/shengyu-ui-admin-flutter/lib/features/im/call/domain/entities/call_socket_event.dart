enum CallSocketEventType {
  invite,
  accepted,
  rejected,
  busy,
  cancelled,
  timeout,
  ended,
  deviceTerminated,
  stateSync,
  mediaTokenIssued,
  callRecord,
  missed,
  groupInvite, // 群组通话邀请
  groupJoin, // 加入群组通话
  groupLeave, // 离开群组通话
  groupParticipantUpdate, // 群组通话参与者更新
  mediaStateUpdate, // 媒体状态更新（摄像头/麦克风开关状态）
}

class CallSocketEvent {
  const CallSocketEvent({
    required this.type,
    required this.callSessionId,
    this.payload = const <String, Object?>{},
  });

  final CallSocketEventType type;
  final String callSessionId;
  final Map<String, Object?> payload;
}
