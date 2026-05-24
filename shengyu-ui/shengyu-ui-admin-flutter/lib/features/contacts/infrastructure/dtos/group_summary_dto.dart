import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';

class GroupSummaryDto {
  const GroupSummaryDto({
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

  factory GroupSummaryDto.fromJson(Map<String, dynamic> json) {
    return GroupSummaryDto(
      groupId: '${json['id'] ?? json['groupId'] ?? ''}',
      name: '${json['name'] ?? json['groupName'] ?? ''}',
      memberCount: _parseInt(json['memberCount'] ?? json['memberNum']) ?? 0,
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      myRole: _parseInt(json['myRole'] ?? json['role']) ?? 0,
      pendingJoinRequestCount:
          _parseInt(json['pendingJoinRequestCount'] ?? json['pendingCount']) ??
          0,
      groupMemberItems: _parseGroupMemberItems(json['groupMemberItems']),
    );
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static List<GroupMemberItem> _parseGroupMemberItems(Object? raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) {
        return GroupMemberItem(
          userId: e['userId']?.toString(),
          name: e['name']?.toString(),
          avatar: e['avatar']?.toString(),
        );
      }).toList();
    }
    return const [];
  }
}
