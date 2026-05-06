import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class Conversation {
  const Conversation({
    required this.chatId,
    required this.title,
    required this.conversationType,
    this.conversationVersion,
    this.targetId,
    this.targetAvatar,
    required this.lastMessageId,
    this.lastMessageSequence,
    this.lastReadSequence,
    required this.lastMessagePreview,
    required this.lastMessageType,
    required this.lastMessageStatus,
    this.lastMessageHasAtMe = false,
    this.groupMemberCount = 0,
    required this.updatedAt,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    this.online = false,
    this.onlineDeviceTypes = const <int>[],
    this.lastActiveTime,
  });

  final String chatId;
  final String title;
  final ConversationType conversationType;
  final String? conversationVersion;
  final String? targetId;
  final String? targetAvatar;
  final String? lastMessageId;
  final String? lastMessageSequence;
  final String? lastReadSequence;
  final String lastMessagePreview;
  final MessageType lastMessageType;
  final MessageStatus lastMessageStatus;
  final bool lastMessageHasAtMe;
  final int groupMemberCount;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool online;
  final List<int> onlineDeviceTypes;
  final int? lastActiveTime;

  Conversation copyWith({
    String? chatId,
    String? title,
    ConversationType? conversationType,
    String? conversationVersion,
    String? targetId,
    String? targetAvatar,
    String? lastMessageId,
    String? lastMessageSequence,
    String? lastReadSequence,
    String? lastMessagePreview,
    MessageType? lastMessageType,
    MessageStatus? lastMessageStatus,
    bool? lastMessageHasAtMe,
    int? groupMemberCount,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? online,
    List<int>? onlineDeviceTypes,
    int? lastActiveTime,
  }) {
    return Conversation(
      chatId: chatId ?? this.chatId,
      title: title ?? this.title,
      conversationType: conversationType ?? this.conversationType,
      conversationVersion: conversationVersion ?? this.conversationVersion,
      targetId: targetId ?? this.targetId,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageSequence: lastMessageSequence ?? this.lastMessageSequence,
      lastReadSequence: lastReadSequence ?? this.lastReadSequence,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      lastMessageHasAtMe: lastMessageHasAtMe ?? this.lastMessageHasAtMe,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      online: online ?? this.online,
      onlineDeviceTypes: onlineDeviceTypes ?? this.onlineDeviceTypes,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
    );
  }
}
