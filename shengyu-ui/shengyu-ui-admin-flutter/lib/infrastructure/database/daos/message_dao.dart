import 'package:drift/drift.dart';

import '../tables/messages_table.dart';
import '../im_database.dart';

// 注意：本 DAO 中使用的 Message 类型是 Drift 生成的数据类（来自 im_database.dart）
// 而非 domain entity Message。两者同名，此处使用 Drift 生成的类型。

part 'message_dao.g.dart';

/// 消息数据访问对象
@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<ImDatabase> with _$MessageDaoMixin {
  MessageDao(ImDatabase db) : super(db);

  /// 查询特定会话的消息列表（按发送时间降序）
  Future<List<Message>> getMessagesByChatId(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 监听特定会话的消息列表变化
  Stream<List<Message>> watchMessagesByChatId(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)])
          ..limit(limit, offset: offset))
        .watch();
  }

  /// 插入单条消息（忽略重复）
  Future<void> insertMessage(Message message) {
    return into(messages).insert(message, mode: InsertMode.insertOrIgnore);
  }

  /// 批量插入消息
  Future<void> insertMessages(List<Message> messagesList) {
    return batch((b) {
      b.insertAll(messages, messagesList, mode: InsertMode.insertOrIgnore);
    });
  }

  /// 更新消息状态
  Future<int> updateMessageStatus(String messageId, MessageStatusDb status) {
    return (update(messages)..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
  }

  /// 更新消息内容
  Future<int> updateMessageContent(String messageId, String content) {
    return (update(messages)..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(content: Value(content)));
  }

  /// 更新消息 extraJson
  Future<int> updateMessageExtraJson(String messageId, String extraJson) {
    return (update(messages)..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(extraJson: Value(extraJson)));
  }

  /// 根据 messageId 查询单条消息
  Future<Message?> getMessageById(String messageId) {
    return (select(messages)
          ..where((m) => m.messageId.equals(messageId)))
        .getSingleOrNull();
  }

  /// 根据 clientMessageId 查询消息（用于去重）
  Future<Message?> getMessageByClientMessageId(String clientMessageId) {
    return (select(messages)
          ..where((m) => m.clientMessageId.equals(clientMessageId)))
        .getSingleOrNull();
  }

  /// 删除会话的所有消息
  Future<int> deleteMessagesByChatId(String chatId) {
    return (delete(messages)..where((m) => m.chatId.equals(chatId))).go();
  }

  /// 【新增】删除指定用户指定会话的消息（带用户隔离）
  Future<int> deleteMessagesByChatIdForUser({
    required String userId,
    required String chatId,
  }) {
    return (delete(messages)
          ..where((m) => m.userId.equals(userId) & m.chatId.equals(chatId)))
        .go();
  }

  /// 删除单条消息
  Future<int> deleteMessage(String messageId) {
    return (delete(messages)
          ..where((m) => m.messageId.equals(messageId)))
        .go();
  }

  /// 获取会话的消息数量
  Future<int> getMessageCount(String chatId) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId)))
        .get()
        .then((list) => list.length);
  }

  /// 【新增】查询特定会话的消息列表（带用户隔离，按发送时间升序）
  Future<List<Message>> getMessagesByChatIdForUser({
    required String userId,
    required String chatId,
    int limit = 500,
  }) {
    return (select(messages)
          ..where((m) => m.userId.equals(userId) & m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.asc(m.sentAt)])
          ..limit(limit))
        .get();
  }

  /// 【新增】获取历史消息（在某个时间点之前，带用户隔离）
  ///
  /// 修复：原实现按 sequence 字符串排序，但 sequence 是 nullable text 类型，
  /// 字符串比较在位数不同时结果错误（"9" > "10"）。改为按 sentAt 排序。
  Future<List<Message>> getOlderMessagesForUser({
    required String userId,
    required String chatId,
    required DateTime beforeSentAt,
    int limit = 50,
  }) {
    return (select(messages)
          ..where((m) =>
              m.userId.equals(userId) &
              m.chatId.equals(chatId) &
              m.sentAt.isSmallerThanValue(beforeSentAt))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)])
          ..limit(limit))
        .get();
  }

  /// 【新增】批量插入或替换消息（用于缓存更新）
  Future<void> upsertMessagesForUser(List<MessagesCompanion> companions) async {
    await batch((batch) {
      for (final companion in companions) {
        batch.insert(
          messages,
          companion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 【新增】清理过期消息（按用户）
  Future<void> cleanExpiredMessagesForUser({
    required String userId,
    required DateTime before,
  }) async {
    await (delete(messages)
          ..where((m) =>
              m.userId.equals(userId) &
              m.cachedAt.isSmallerThanValue(before.millisecondsSinceEpoch)))
        .go();
  }
}
