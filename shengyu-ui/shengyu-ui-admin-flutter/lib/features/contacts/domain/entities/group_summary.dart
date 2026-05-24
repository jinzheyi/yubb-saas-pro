import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';

class GroupSummary {
  const GroupSummary({
    required this.groupId,
    required this.name,
    required this.memberCount,
    this.avatarUrl,
    this.myRole = 0,
    this.pendingJoinRequestCount = 0,
    this.groupMemberItems = const [],
  });

  final String groupId;
  final String name;
  final int memberCount;
  final String? avatarUrl;
  final int myRole;
  final int pendingJoinRequestCount;
  final List<GroupMemberItem> groupMemberItems;
}
