class CallSessionDto {
  const CallSessionDto({
    required this.callSessionId,
    required this.chatId,
    required this.callType,
    required this.status,
    this.inviteId,
    this.title,
    this.elapsedSeconds,
    this.acceptedDeviceId,
    this.callerProfile,
    this.calleeProfile,
    this.rtcRoom,
  });

  final String callSessionId;
  final String chatId;
  final String callType;
  final String status;
  final String? inviteId;
  final String? title;
  final int? elapsedSeconds;
  final String? acceptedDeviceId;
  final CallParticipantDto? callerProfile;
  final CallParticipantDto? calleeProfile;
  final CallRtcRoomDto? rtcRoom;

  factory CallSessionDto.fromJson(Map<String, dynamic> json) {
    return CallSessionDto(
      callSessionId: json['callSessionId']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      callType: json['callType']?.toString() ?? 'audio',
      status: json['status']?.toString() ?? 'connecting',
      inviteId: json['inviteId']?.toString(),
      title: json['title']?.toString(),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt(),
      acceptedDeviceId: json['acceptedDeviceId']?.toString(),
      callerProfile: _participantFromJson(json['callerProfile']),
      calleeProfile: _participantFromJson(json['calleeProfile']),
      rtcRoom: _rtcRoomFromJson(json['rtcRoom'] ?? json['roomBundle']),
    );
  }

  static CallParticipantDto? _participantFromJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return CallParticipantDto.fromJson(raw);
    }
    return null;
  }

  static CallRtcRoomDto? _rtcRoomFromJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return CallRtcRoomDto.fromJson(raw);
    }
    return null;
  }
}

class CallParticipantDto {
  const CallParticipantDto({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory CallParticipantDto.fromJson(Map<String, dynamic> json) {
    return CallParticipantDto(
      userId: json['userId']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ?? json['nickname']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class CallRtcRoomDto {
  const CallRtcRoomDto({
    required this.callSessionId,
    required this.roomId,
    required this.publisherId,
    required this.displayName,
    required this.janusUrl,
    required this.turnUrls,
    required this.turnUsername,
    required this.turnCredential,
    required this.token,
  });

  final String callSessionId;
  final String roomId;
  final String publisherId;
  final String displayName;
  final String janusUrl;
  final List<String> turnUrls;
  final String turnUsername;
  final String turnCredential;
  final String token;

  factory CallRtcRoomDto.fromJson(Map<String, dynamic> json) {
    final rawTurnUrls = json['turnUrls'] as List<dynamic>? ?? const [];
    return CallRtcRoomDto(
      callSessionId: json['callSessionId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      publisherId: json['publisherId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      janusUrl: json['janusUrl']?.toString() ?? '',
      turnUrls: rawTurnUrls.map((item) => item.toString()).toList(),
      turnUsername: json['turnUsername']?.toString() ?? '',
      turnCredential: json['turnCredential']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}
