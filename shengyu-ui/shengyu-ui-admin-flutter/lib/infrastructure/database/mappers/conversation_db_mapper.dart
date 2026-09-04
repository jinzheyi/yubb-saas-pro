import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/tables/conversations_table.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart'
    as domain;
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

/// 会话 Domain Entity ↔ Drift 数据库行 映射器
class ConversationDbMapper {
  /// Domain Entity → Drift Companion（用于写入数据库）
  static ConversationsCompanion toCompanion(
    domain.Conversation entity, {
    required String userId,
  }) {
    return ConversationsCompanion(
      chatId: Value(entity.chatId),
      type: Value(_toDbType(entity.conversationType)),
      targetName: Value(entity.title),
      targetAvatar: Value(entity.targetAvatar),
      targetId: Value(entity.targetId),
      lastMessageId: Value(entity.lastMessageId),
      lastMessageSequence: Value(entity.lastMessageSequence),
      lastReadSequence: Value(entity.lastReadSequence),
      lastMessagePreview: Value(entity.lastMessagePreview),
      lastMessageType: Value(entity.lastMessageType.name),
      lastMessageSenderName: Value(entity.lastMessageSenderName),
      lastMessageIsSelf: Value(entity.lastMessageIsSelf),
      lastMessageStatus: Value(entity.lastMessageStatus.name),
      lastMessageHasAtMe: Value(entity.lastMessageHasAtMe),
      lastMessageTime: Value(entity.updatedAt),
      unreadCount: Value(entity.unreadCount),
      isPinned: Value(entity.isPinned),
      isMuted: Value(entity.isMuted),
      updatedAt: Value(entity.updatedAt),
      userId: Value(userId),
      cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      groupMemberCount: Value(entity.groupMemberCount),
      groupMemberStatus: Value(entity.groupMemberStatus),
      groupMemberAvatarsJson: Value(jsonEncode(entity.groupMemberAvatars)),
      groupMemberItemsJson: Value(
        jsonEncode(
          entity.groupMemberItems
              .map(
                (item) => <String, String?>{
                  'userId': item.userId,
                  'name': item.name,
                  'avatar': item.avatar,
                },
              )
              .toList(),
        ),
      ),
    );
  }

  /// Drift 查询结果 → Domain Entity
  static domain.Conversation toEntity(Conversation row) {
    return domain.Conversation(
      chatId: row.chatId,
      title: row.targetName,
      conversationType: _fromDbType(row.type),
      targetId: row.targetId,
      targetAvatar: row.targetAvatar,
      lastMessageId: row.lastMessageId,
      lastMessageSequence: row.lastMessageSequence,
      lastReadSequence: row.lastReadSequence,
      lastMessagePreview: row.lastMessagePreview,
      lastMessageType: _parseMessageType(row.lastMessageType),
      lastMessageSenderName: row.lastMessageSenderName,
      lastMessageIsSelf: row.lastMessageIsSelf,
      lastMessageStatus: _parseMessageStatus(row.lastMessageStatus),
      lastMessageHasAtMe: row.lastMessageHasAtMe,
      updatedAt: row.lastMessageTime,
      unreadCount: row.unreadCount,
      isPinned: row.isPinned,
      isMuted: row.isMuted,
      groupMemberCount: row.groupMemberCount,
      groupMemberStatus: row.groupMemberStatus,
      groupMemberAvatars: _parseStringList(row.groupMemberAvatarsJson),
      groupMemberItems: _parseGroupMemberItems(row.groupMemberItemsJson),
    );
  }

  static ConversationTypeDb _toDbType(ConversationType type) {
    switch (type) {
      case ConversationType.direct:
        return ConversationTypeDb.single;
      case ConversationType.group:
        return ConversationTypeDb.group;
    }
  }

  static ConversationType _fromDbType(ConversationTypeDb type) {
    switch (type) {
      case ConversationTypeDb.single:
        return ConversationType.direct;
      case ConversationTypeDb.group:
        return ConversationType.group;
      case ConversationTypeDb.system:
        return ConversationType.direct; // fallback
    }
  }

  static MessageType _parseMessageType(String? raw) {
    if (raw == null) return MessageType.text;
    return MessageType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MessageType.text,
    );
  }

  static MessageStatus _parseMessageStatus(String? raw) {
    if (raw == null) return MessageStatus.sent;
    return MessageStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MessageStatus.sent,
    );
  }

  static List<String> _parseStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((value) => value?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static List<domain.GroupMemberItem> _parseGroupMemberItems(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => domain.GroupMemberItem(
              userId: item['userId']?.toString(),
              name: item['name']?.toString(),
              avatar: item['avatar']?.toString(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
