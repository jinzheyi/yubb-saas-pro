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
