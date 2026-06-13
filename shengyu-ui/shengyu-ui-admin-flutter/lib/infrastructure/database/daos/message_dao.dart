import 'package:drift/drift.dart';

import '../tables/messages_table.dart';
import '../im_database.dart';

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
}
