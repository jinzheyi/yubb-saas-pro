import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';

/// 通话状态枚举
enum CallStatus {
  /// 与服务端 ImCallStatusEnum 保持严格一致：1=未接听，2=已接通。
  missed(1, '未接听'),
  completed(2, '已接通'),
  rejected(3, '已拒绝'),
  busy(4, '忙线'),
  cancelled(5, '已取消');

  final int value;
  final String label;

  const CallStatus(this.value, this.label);

  static CallStatus fromValue(Object? raw) {
    final value = switch (raw) {
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    return CallStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CallStatus.missed,
    );
  }
}

/// 通话记录消息实体
///
/// 用于在聊天窗口中展示通话记录,以系统消息形式展示
/// 参考微信通话记录展示方式：
/// - 1v1通话："{发起人}发起了{语音/视频}通话" / "{语音/视频}通话已经结束"
/// - 群通话："{发起人}发起了群语音/视频通话" / "群通话已结束"
class CallRecordMessage {
  const CallRecordMessage({
    required this.callId,
    required this.callType,
    required this.status,
    required this.duration,
    required this.callerId,
    required this.calleeId,
    required this.initiateTime,
    this.callerName,
    this.calleeName,
    this.isGroupCall = false,
    this.inviteeNames = const [],
    this.groupName,
  });

  /// 通话ID
  final String callId;

  /// 通话类型(语音/视频)
  final CallType callType;

  /// 通话状态
  final CallStatus status;

  /// 通话时长(秒)
  final int duration;

  /// 主叫用户ID
  final String callerId;

  /// 被叫用户ID
  final String calleeId;

  /// 发起时间(毫秒时间戳)
  final int initiateTime;

  /// 主叫用户昵称（用于展示）
  final String? callerName;

  /// 被叫用户昵称（用于展示）
  final String? calleeName;

  /// 是否群通话
  final bool isGroupCall;

  /// 被邀请成员昵称列表（群通话使用）
  final List<String> inviteeNames;

  /// 群组名称（群通话使用）
  final String? groupName;

  /// 从 JSON 反序列化
  factory CallRecordMessage.fromJson(Map<String, dynamic> json) {
    return CallRecordMessage(
      callId: json['callId']?.toString() ?? '',
      callType: _parseCallType(json['callType']),
      status: CallStatus.fromValue(json['status'] ?? json['callStatus']),
      duration: _parseInt(json['duration']),
      callerId: json['callerId']?.toString() ?? '',
      calleeId: json['calleeId']?.toString() ?? '',
      initiateTime: _parseInt(json['initiateTime']),
      callerName: json['callerName']?.toString(),
      calleeName: json['calleeName']?.toString(),
      isGroupCall: json['isGroupCall'] as bool? ?? false,
      inviteeNames: _parseInviteeNames(json['inviteeNames']),
      groupName: json['groupName']?.toString(),
    );
  }

  /// 解析被邀请成员列表
  static List<String> _parseInviteeNames(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static int _parseInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  /// 解析通话类型
  static CallType _parseCallType(dynamic raw) {
    if (raw is int) {
      return raw == 2 ? CallType.video : CallType.audio;
    }
    if (raw is String) {
      return raw.toLowerCase() == 'video' ? CallType.video : CallType.audio;
    }
    return CallType.audio;
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callType': callType == CallType.video ? 2 : 1,
      'status': status.value,
      'duration': duration,
      'callerId': callerId,
      'calleeId': calleeId,
      'initiateTime': initiateTime,
      'callerName': callerName,
      'calleeName': calleeName,
      'isGroupCall': isGroupCall,
      'inviteeNames': inviteeNames,
      'groupName': groupName,
    };
  }
}
