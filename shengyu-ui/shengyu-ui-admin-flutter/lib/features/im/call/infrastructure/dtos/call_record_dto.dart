import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

/// 通话记录 DTO
class CallRecordDto {
  final String callId;
  final String chatId;
  final int callType;
  final int status;
  final int duration;
  final String callerId;
  final String calleeId;
  final String? callerName;
  final String? callerAvatar;
  final String? calleeName;
  final String? calleeAvatar;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCaller;
  final ConversationType conversationType;
  final List<String> inviteeNames;

  const CallRecordDto({
    required this.callId,
    required this.chatId,
    required this.callType,
    required this.status,
    required this.duration,
    required this.callerId,
    required this.calleeId,
    this.callerName,
    this.callerAvatar,
    this.calleeName,
    this.calleeAvatar,
    required this.startTime,
    this.endTime,
    required this.isCaller,
    this.conversationType = ConversationType.direct,
    this.inviteeNames = const [],
  });

  factory CallRecordDto.fromJson(Map<String, dynamic> json) {
    return CallRecordDto(
      callId: json['callId']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      callType: json['callType'] as int? ?? 1,
      status: json['status'] as int? ?? 1,
      duration: json['duration'] as int? ?? 0,
      callerId: json['callerId']?.toString() ?? '',
      calleeId: json['calleeId']?.toString() ?? '',
      callerName: json['callerName']?.toString(),
      callerAvatar: json['callerAvatar']?.toString(),
      calleeName: json['calleeName']?.toString(),
      calleeAvatar: json['calleeAvatar']?.toString(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      isCaller: json['isCaller'] as bool? ?? false,
      conversationType: (json['conversationType'] as int? ?? 1) == 2
          ? ConversationType.group
          : ConversationType.direct,
      inviteeNames: json['inviteeNames'] is List
          ? (json['inviteeNames'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'chatId': chatId,
      'callType': callType,
      'status': status,
      'duration': duration,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'calleeName': calleeName,
      'calleeAvatar': calleeAvatar,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCaller': isCaller,
      'conversationType': conversationType == ConversationType.group ? 2 : 1,
      if (inviteeNames.isNotEmpty) 'inviteeNames': inviteeNames,
    };
  }
}
