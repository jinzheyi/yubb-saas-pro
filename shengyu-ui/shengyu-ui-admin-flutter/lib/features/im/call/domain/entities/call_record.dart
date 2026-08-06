import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

/// 通话记录实体
class CallRecord {
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

  const CallRecord({
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
  });

  /// 获取对方用户ID
  String get peerId => isCaller ? calleeId : callerId;

  /// 获取对方昵称
  String? get peerName => isCaller ? calleeName : callerName;

  /// 获取对方头像
  String? get peerAvatar => isCaller ? calleeAvatar : callerAvatar;
}
