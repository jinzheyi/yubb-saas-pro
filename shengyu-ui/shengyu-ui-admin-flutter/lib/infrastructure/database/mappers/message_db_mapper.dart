import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/tables/messages_table.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart' as domain;
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

/// 消息 Domain Entity ↔ Drift 数据库行 映射器
class MessageDbMapper {
  /// Domain Entity → Drift Companion（用于写入数据库）
  static MessagesCompanion toCompanion(
    domain.Message entity, {
    required String userId,
  }) {
    return MessagesCompanion(
      messageId: Value(entity.messageId),
      clientMessageId: Value(entity.clientMessageId),
      chatId: Value(entity.chatId),
      type: Value(_toDbType(entity.type)),
      status: Value(_toDbStatus(entity.status)),
      content: Value(entity.content),
      senderId: Value(entity.senderId),
      senderName: Value(entity.senderName),
      senderAvatar: Value(entity.senderAvatar),
      sentAt: Value(entity.sentAt),
      sequence: Value(entity.sequence),
      isOutgoing: Value(entity.isOutgoing),
      extraJson: Value(_encodeExtra(entity.extra)),
      quoteInfoJson: Value(_encodeQuoteInfo(entity.quoteInfo)),
      createdAt: Value(DateTime.now()),
      userId: Value(userId),
      cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Drift 查询结果 → Domain Entity
  static domain.Message toEntity(Message row) {
    return domain.Message(
      messageId: row.messageId,
      chatId: row.chatId,
      senderId: row.senderId,
      senderName: row.senderName,
      senderAvatar: row.senderAvatar,
      type: _fromDbTypeType(row.type),
      status: _fromDbStatus(row.status),
      content: row.content,
      sentAt: row.sentAt,
      isOutgoing: row.isOutgoing,
      clientMessageId: row.clientMessageId,
      sequence: row.sequence,
      quoteInfo: _decodeQuoteInfo(row.quoteInfoJson),
      extra: _decodeExtra(row.extraJson),
    );
  }

  static MessageTypeDb _toDbType(MessageType type) {
    switch (type) {
      case MessageType.text: return MessageTypeDb.text;
      case MessageType.image: return MessageTypeDb.image;
      case MessageType.voice: return MessageTypeDb.voice;
      case MessageType.video: return MessageTypeDb.video;
      case MessageType.file: return MessageTypeDb.file;
      case MessageType.system: return MessageTypeDb.system;
      default: return MessageTypeDb.text;
    }
  }

  static MessageType _fromDbTypeType(MessageTypeDb type) {
    switch (type) {
      case MessageTypeDb.text: return MessageType.text;
      case MessageTypeDb.image: return MessageType.image;
      case MessageTypeDb.voice: return MessageType.voice;
      case MessageTypeDb.video: return MessageType.video;
      case MessageTypeDb.file: return MessageType.file;
      case MessageTypeDb.system: return MessageType.system;
    }
  }

  static MessageStatusDb _toDbStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending: return MessageStatusDb.sending;
      case MessageStatus.sent: return MessageStatusDb.sent;
      case MessageStatus.delivered: return MessageStatusDb.delivered;
      case MessageStatus.failed: return MessageStatusDb.failed;
      case MessageStatus.recalled: return MessageStatusDb.recalled;
      default: return MessageStatusDb.sent;
    }
  }

  static MessageStatus _fromDbStatus(MessageStatusDb status) {
    switch (status) {
      case MessageStatusDb.sending: return MessageStatus.sending;
      case MessageStatusDb.sent: return MessageStatus.sent;
      case MessageStatusDb.delivered: return MessageStatus.delivered;
      case MessageStatusDb.failed: return MessageStatus.failed;
      case MessageStatusDb.recalled: return MessageStatus.recalled;
    }
  }

  static String? _encodeExtra(MessageExtra extra) {
    if (extra == const MessageExtra()) return null;
    return jsonEncode(extra.toJson());
  }

  static MessageExtra _decodeExtra(String? json) {
    if (json == null || json.isEmpty) return const MessageExtra();
    try {
      return MessageExtra.fromJson(jsonDecode(json));
    } catch (_) {
      return const MessageExtra();
    }
  }

  static String? _encodeQuoteInfo(QuoteInfo? quoteInfo) {
    if (quoteInfo == null) return null;
    return jsonEncode(quoteInfo.toJson());
  }

  static QuoteInfo? _decodeQuoteInfo(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return QuoteInfo.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }
}
