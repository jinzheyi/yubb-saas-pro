import 'package:drift/drift.dart';

/// 消息类型枚举
enum MessageTypeDb { text, image, voice, video, file, system }

/// 消息状态枚举
enum MessageStatusDb { sending, sent, delivered, failed, recalled }

/// 按会话ID查询消息的索引
@TableIndex(name: 'idx_messages_chat_id', columns: {#chatId})
/// 客户端消息ID唯一索引（用于去重）
@TableIndex(
    name: 'idx_messages_client_message_id', columns: {#clientMessageId}, unique: true)
/// 消息表定义
class Messages extends Table {
  /// 主键，消息ID（服务器生成）
  TextColumn get messageId => text()();

  /// 客户端消息ID（用于去重）
  TextColumn get clientMessageId => text().nullable()();

  /// 会话ID（索引，用于查询特定聊天的消息）
  TextColumn get chatId => text()();

  /// 消息类型
  IntColumn get type => intEnum<MessageTypeDb>()();

  /// 消息状态
  IntColumn get status => intEnum<MessageStatusDb>()();

  /// 消息内容（文本或JSON序列化数据）
  TextColumn get content => text()();

  /// 发送者ID
  TextColumn get senderId => text()();

  /// 发送者名称
  TextColumn get senderName => text()();

  /// 发送者头像URL（可选）
  TextColumn get senderAvatar => text().nullable()();

  /// 发送时间
  DateTimeColumn get sentAt => dateTime()();

  /// 服务器序列号（可选）
  TextColumn get sequence => text().nullable()();

  /// 是否是自己发送的
  BoolColumn get isOutgoing => boolean()();

  /// MessageExtra序列化JSON
  TextColumn get extraJson => text().nullable()();

  /// 本地创建时间戳
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId};
}
