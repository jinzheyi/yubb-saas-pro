import 'package:drift/drift.dart';

/// 会话类型枚举
enum ConversationTypeDb { single, group, system }

/// 会话表定义
class Conversations extends Table {
  /// 主键，会话ID
  TextColumn get chatId => text()();

  /// 会话类型
  IntColumn get type => intEnum<ConversationTypeDb>()();

  /// 会话名称
  TextColumn get targetName => text()();

  /// 会话头像URL
  TextColumn get targetAvatar => text().nullable()();

  /// 最后一条消息ID
  TextColumn get lastMessageId => text().nullable()();

  /// 最后一条消息预览文本
  TextColumn get lastMessagePreview => text()();

  /// 最后一条消息时间
  DateTimeColumn get lastMessageTime => dateTime()();

  /// 未读数
  IntColumn get unreadCount => integer()();

  /// 是否置顶
  BoolColumn get isPinned => boolean()();

  /// 是否免打扰
  BoolColumn get isMuted => boolean()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId};

  @override
  List<String> get customConstraints => ['UNIQUE(chatId)'];
}
