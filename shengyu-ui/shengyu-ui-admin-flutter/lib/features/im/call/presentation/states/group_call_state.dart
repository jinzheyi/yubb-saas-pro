import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';

/// 群通话状态
///
/// 用于群聊通话状态栏显示，表示当前群组是否有正在进行的通话
class GroupCallState {
  const GroupCallState({
    this.groupId = '',
    this.hasActiveCall = false,
    this.callType = 'voice',
    this.participantCount = 0,
    this.participants = const [],
    this.elapsedSeconds = 0,
  });

  /// 群组ID
  final String groupId;

  /// 是否有正在进行的通话
  final bool hasActiveCall;

  /// 通话类型：'voice' 或 'video'
  final String callType;

  /// 参与人数
  final int participantCount;

  /// 参与者列表
  final List<CallParticipantProfile> participants;

  /// 通话时长（秒）
  final int elapsedSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupCallState &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          hasActiveCall == other.hasActiveCall &&
          callType == other.callType &&
          participantCount == other.participantCount &&
          elapsedSeconds == other.elapsedSeconds;

  @override
  int get hashCode =>
      groupId.hashCode ^
      hasActiveCall.hashCode ^
      callType.hashCode ^
      participantCount.hashCode ^
      elapsedSeconds.hashCode;

  @override
  String toString() {
    return 'GroupCallState('
        'groupId: $groupId, '
        'hasActiveCall: $hasActiveCall, '
        'callType: $callType, '
        'participantCount: $participantCount, '
        'elapsedSeconds: $elapsedSeconds)';
  }
}
