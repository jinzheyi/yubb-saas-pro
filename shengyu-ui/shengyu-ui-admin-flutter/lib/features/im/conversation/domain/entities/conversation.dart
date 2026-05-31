import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

/// 群成员信息项（用于组合头像）
class GroupMemberItem {
  final String? userId;
  final String? name;
  final String? avatar;

  const GroupMemberItem({this.userId, this.name, this.avatar});
}

class Conversation {
  const Conversation({
    required this.chatId,
    required this.title,
    required this.conversationType,
    this.conversationVersion,
    this.targetId,
    this.targetAvatar,
    this.avatarText,
    this.avatarBg,
    required this.lastMessageId,
    this.lastMessageSequence,
    this.lastReadSequence,
    required this.lastMessagePreview,
    required this.lastMessageType,
    this.lastMessageSenderName,
    this.lastMessageIsSelf = false,
    this.lastMessageCustomType,
    this.lastMessageFileName,
    this.lastMessageSystemEventKey,
    required this.lastMessageStatus,
    this.lastMessageHasAtMe = false,
    this.groupMemberCount = 0,
    this.groupMemberAvatars = const [],
    this.groupMemberItems = const [],
    required this.updatedAt,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    this.deletedByUser = false,
    this.online = false,
    this.onlineDeviceTypes = const <int>[],
    this.lastActiveTime,
    this.groupMemberStatus,
  });

  final String chatId;
  final String title;
  final ConversationType conversationType;
  final String? conversationVersion;
  final String? targetId;
  final String? targetAvatar;
  final String? avatarText;
  final String? avatarBg;
  final String? lastMessageId;
  final String? lastMessageSequence;
  final String? lastReadSequence;
  final String lastMessagePreview;
  final MessageType lastMessageType;
  final String? lastMessageSenderName;
  final bool lastMessageIsSelf;
  final String? lastMessageCustomType;
  final String? lastMessageFileName;
  final String? lastMessageSystemEventKey;
  final MessageStatus lastMessageStatus;
  final bool lastMessageHasAtMe;
  final int groupMemberCount;
  final List<String> groupMemberAvatars;
  final List<GroupMemberItem> groupMemberItems;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool deletedByUser;
  final bool online;
  final List<int> onlineDeviceTypes;
  final int? lastActiveTime;
  final int? groupMemberStatus;

  bool get isGroupLeft => groupMemberStatus == 1;
  bool get isGroupKicked => groupMemberStatus == 2;
  bool get isGroupDisbanded => groupMemberStatus == 3;
  bool get canSendMessageToGroup => groupMemberStatus == null || groupMemberStatus == 0;
  String get groupStatusText {
    switch (groupMemberStatus) {
      case 1:
        return '已退出';
      case 2:
        return '已被踢';
      case 3:
        return '已解散';
      default:
        return '';
    }
  }

  Conversation copyWith({
    String? chatId,
    String? title,
    ConversationType? conversationType,
    String? conversationVersion,
    String? targetId,
    String? targetAvatar,
    String? avatarText,
    String? avatarBg,
    String? lastMessageId,
    String? lastMessageSequence,
    String? lastReadSequence,
    String? lastMessagePreview,
    MessageType? lastMessageType,
    String? lastMessageSenderName,
    bool? lastMessageIsSelf,
    String? lastMessageCustomType,
    String? lastMessageFileName,
    String? lastMessageSystemEventKey,
    MessageStatus? lastMessageStatus,
    bool? lastMessageHasAtMe,
    int? groupMemberCount,
    List<String>? groupMemberAvatars,
    List<GroupMemberItem>? groupMemberItems,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? deletedByUser,
    bool? online,
    List<int>? onlineDeviceTypes,
    int? lastActiveTime,
    int? groupMemberStatus,
  }) {
    return Conversation(
      chatId: chatId ?? this.chatId,
      title: title ?? this.title,
      conversationType: conversationType ?? this.conversationType,
      conversationVersion: conversationVersion ?? this.conversationVersion,
      targetId: targetId ?? this.targetId,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      avatarText: avatarText ?? this.avatarText,
      avatarBg: avatarBg ?? this.avatarBg,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageSequence: lastMessageSequence ?? this.lastMessageSequence,
      lastReadSequence: lastReadSequence ?? this.lastReadSequence,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageIsSelf: lastMessageIsSelf ?? this.lastMessageIsSelf,
      lastMessageCustomType:
          lastMessageCustomType ?? this.lastMessageCustomType,
      lastMessageFileName: lastMessageFileName ?? this.lastMessageFileName,
      lastMessageSystemEventKey:
          lastMessageSystemEventKey ?? this.lastMessageSystemEventKey,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      lastMessageHasAtMe: lastMessageHasAtMe ?? this.lastMessageHasAtMe,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      groupMemberAvatars: groupMemberAvatars ?? this.groupMemberAvatars,
      groupMemberItems: groupMemberItems ?? this.groupMemberItems,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      deletedByUser: deletedByUser ?? this.deletedByUser,
      online: online ?? this.online,
      onlineDeviceTypes: onlineDeviceTypes ?? this.onlineDeviceTypes,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      groupMemberStatus: groupMemberStatus ?? this.groupMemberStatus,
    );
  }
}
