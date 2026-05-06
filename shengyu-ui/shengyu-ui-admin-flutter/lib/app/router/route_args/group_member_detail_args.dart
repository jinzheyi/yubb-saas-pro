import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';

class GroupMemberDetailArgs {
  const GroupMemberDetailArgs({
    required this.groupContext,
    required this.memberUserId,
    required this.memberName,
    required this.memberRoleCode,
    required this.colorValue,
    this.avatarUrl,
    this.canTransferOwner = false,
    this.canRemoveMember = false,
    this.canToggleAdmin = false,
    this.canToggleMute = false,
    this.joinTime,
    this.muteEndTime,
    this.isMuted = false,
  });

  final GroupContextArgs groupContext;
  final String memberUserId;
  final String memberName;
  final int memberRoleCode;
  final int colorValue;
  final String? avatarUrl;
  final bool canTransferOwner;
  final bool canRemoveMember;
  final bool canToggleAdmin;
  final bool canToggleMute;
  final String? joinTime;
  final DateTime? muteEndTime;
  final bool isMuted;
}
