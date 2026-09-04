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

  /// 对方用户ID（单聊时的 targetId）
  TextColumn get targetId => text().nullable()();

  /// 最后一条消息ID
  TextColumn get lastMessageId => text().nullable()();

  /// 最后一条消息序列号
  TextColumn get lastMessageSequence => text().nullable()();

  /// 最后已读序列号
  TextColumn get lastReadSequence => text().nullable()();

  /// 最后一条消息预览文本
  TextColumn get lastMessagePreview => text()();

  /// 最后一条消息类型（存储为字符串名称）
  TextColumn get lastMessageType => text()();

  /// 最后一条消息发送者名称
  TextColumn get lastMessageSenderName => text().nullable()();

  /// 最后一条消息是否自己发送
  BoolColumn get lastMessageIsSelf =>
      boolean().withDefault(const Constant(false))();

  /// 最后一条消息状态（存储为字符串名称）
  TextColumn get lastMessageStatus =>
      text().withDefault(const Constant('sent'))();

  /// 是否有 @我
  BoolColumn get lastMessageHasAtMe =>
      boolean().withDefault(const Constant(false))();

  /// 最后一条消息时间
  DateTimeColumn get lastMessageTime => dateTime()();

  /// 未读数
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// 是否置顶
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// 是否免打扰
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  /// === 用户隔离 ===
  TextColumn get userId => text().withDefault(const Constant(''))();

  /// === 缓存时间戳（毫秒级） ===
  /// 注意：此字段由 Mapper 显式设置，不使用默认值以避免类加载时固定时间戳
  IntColumn get cachedAt => integer()();

  /// === 群成员数量 ===
  IntColumn get groupMemberCount => integer().withDefault(const Constant(0))();

  /// === 群成员状态（1=已退出, 2=已被踢, 3=已解散） ===
  IntColumn get groupMemberStatus => integer().nullable()();

  /// 用于组合群头像的成员头像列表 JSON。
  ///
  /// 冷启动时会话列表直接从本地缓存恢复；若不持久化这些资料，群头像会
  /// 退化为首字母占位符。
  TextColumn get groupMemberAvatarsJson => text().nullable()();

  /// 用于组合群头像的成员信息 JSON（最多只在 UI 使用前几个成员）。
  TextColumn get groupMemberItemsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {chatId};
}
