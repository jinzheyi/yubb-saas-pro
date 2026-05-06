class CallSignalEventDto {
  const CallSignalEventDto({
    required this.type,
    required this.callSessionId,
    this.payload = const <String, Object?>{},
  });

  final String type;
  final String callSessionId;
  final Map<String, Object?> payload;

  factory CallSignalEventDto.fromJson(Map<String, dynamic> json) {
    return CallSignalEventDto(
      type: json['type'] as String? ?? '',
      callSessionId: json['callSessionId'] as String? ?? '',
      payload:
          (json['payload'] as Map<String, dynamic>?)?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
  }
}
