import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';

/// 群通话成员选择页路由参数
class GroupCallMemberSelectArgs {
  const GroupCallMemberSelectArgs({
    required this.groupId,
    required this.groupName,
    required this.callType,
    this.existingMemberIds = const [],
    this.currentUserId = '',
  });

  /// 群组ID
  final String groupId;

  /// 群组名称
  final String groupName;

  /// 通话类型（语音/视频）
  final CallType callType;

  /// 已存在的成员ID列表（用于过滤已在通话中的成员）
  final List<String> existingMemberIds;

  /// 当前用户ID（发起者，用于从列表中过滤）
  final String currentUserId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupCallMemberSelectArgs &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          groupName == other.groupName &&
          callType == other.callType &&
          _listEquals(existingMemberIds, other.existingMemberIds) &&
          currentUserId == other.currentUserId;

  @override
  int get hashCode =>
      groupId.hashCode ^
      groupName.hashCode ^
      callType.hashCode ^
      existingMemberIds.hashCode ^
      currentUserId.hashCode;

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
