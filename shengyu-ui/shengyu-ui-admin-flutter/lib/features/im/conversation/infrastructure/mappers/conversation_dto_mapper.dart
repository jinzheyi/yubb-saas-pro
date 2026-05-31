import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';

abstract final class ConversationDtoMapper {
  static Conversation toEntity(ConversationDto dto) {
    return Conversation(
      chatId: dto.chatId,
      title: dto.title,
      conversationType: dto.conversationType,
      conversationVersion: dto.conversationVersion.isEmpty
          ? null
          : dto.conversationVersion,
      targetId: dto.targetId.isEmpty ? null : dto.targetId,
      targetAvatar: dto.targetAvatar.isEmpty ? null : dto.targetAvatar,
      avatarText: dto.avatarText.isEmpty ? null : dto.avatarText,
      avatarBg: dto.avatarBg.isEmpty ? null : dto.avatarBg,
      lastMessageId: dto.lastMessageId.isEmpty ? null : dto.lastMessageId,
      lastMessageSequence: dto.lastMessageSequence.isEmpty
          ? null
          : dto.lastMessageSequence,
      lastReadSequence: dto.lastReadSequence.isEmpty
          ? null
          : dto.lastReadSequence,
      lastMessagePreview: dto.lastMessagePreview,
      lastMessageType: dto.lastMessageType,
      lastMessageSenderName: dto.lastMessageSenderName.isEmpty
          ? null
          : dto.lastMessageSenderName,
      lastMessageIsSelf: dto.lastMessageIsSelf,
      lastMessageCustomType: dto.lastMessageCustomType.isEmpty
          ? null
          : dto.lastMessageCustomType,
      lastMessageFileName: dto.lastMessageFileName.isEmpty
          ? null
          : dto.lastMessageFileName,
      lastMessageSystemEventKey: dto.lastMessageSystemEventKey.isEmpty
          ? null
          : dto.lastMessageSystemEventKey,
      lastMessageStatus: dto.lastMessageStatus,
      lastMessageHasAtMe: dto.lastMessageHasAtMe,
      groupMemberCount: dto.groupMemberCount,
      groupMemberAvatars: dto.groupMemberAvatars,
      groupMemberItems: dto.groupMemberItems,
      updatedAt: dto.updatedAt,
      unreadCount: dto.unreadCount,
      isPinned: dto.isPinned,
      isMuted: dto.isMuted,
      deletedByUser: dto.deletedByUser,
      online: dto.online,
      onlineDeviceTypes: dto.onlineDeviceTypes,
      lastActiveTime: dto.lastActiveTime > 0 ? dto.lastActiveTime : null,
      groupMemberStatus: dto.groupMemberStatus,
    );
  }
}
