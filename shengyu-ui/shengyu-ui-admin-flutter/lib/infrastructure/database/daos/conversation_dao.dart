import 'package:drift/drift.dart';

import '../tables/conversations_table.dart';
import '../im_database.dart';

part 'conversation_dao.g.dart';

/// 会话数据访问对象
@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<ImDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(ImDatabase db) : super(db);

  /// 查询所有会话列表（按最后消息时间降序）
  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageTime)]))
        .get();
  }

  /// 监听所有会话列表变化
  Stream<List<Conversation>> watchAllConversations() {
    return (select(conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageTime)]))
        .watch();
  }

  /// 根据 chatId 查询单个会话
  Future<Conversation?> getConversationById(String chatId) {
    return (select(conversations)
          ..where((c) => c.chatId.equals(chatId)))
        .getSingleOrNull();
  }

  /// 插入或更新会话
  Future<void> upsertConversation(Conversation conversation) {
    return into(conversations).insert(
      conversation,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// 批量插入或更新会话
  Future<void> upsertConversations(List<Conversation> conversationsList) {
    return batch((b) {
      b.insertAll(
        conversations,
        conversationsList,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// 更新未读数
  Future<int> updateUnreadCount(String chatId, int unreadCount) {
    return (update(conversations)..where((c) => c.chatId.equals(chatId)))
        .write(ConversationsCompanion(unreadCount: Value(unreadCount)));
  }

  /// 更新最后一条消息信息
  Future<int> updateLastMessage(
    String chatId, {
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
  }) {
    return (update(conversations)..where((c) => c.chatId.equals(chatId))).write(
      ConversationsCompanion(
        lastMessageId: lastMessageId != null ? Value(lastMessageId) : const Value.absent(),
        lastMessagePreview:
            lastMessagePreview != null ? Value(lastMessagePreview) : const Value.absent(),
        lastMessageTime:
            lastMessageTime != null ? Value(lastMessageTime) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 切换置顶状态
  Future<int> togglePinned(String chatId, bool isPinned) {
    return (update(conversations)..where((c) => c.chatId.equals(chatId)))
        .write(ConversationsCompanion(isPinned: Value(isPinned)));
  }

  /// 切换免打扰状态
  Future<int> toggleMuted(String chatId, bool isMuted) {
    return (update(conversations)..where((c) => c.chatId.equals(chatId)))
        .write(ConversationsCompanion(isMuted: Value(isMuted)));
  }

  /// 删除会话
  Future<int> deleteConversation(String chatId) {
    return (delete(conversations)..where((c) => c.chatId.equals(chatId))).go();
  }

  /// 获取未读消息总数
  Future<int> getTotalUnreadCount() {
    return (select(conversations)
          ..where((c) => c.unreadCount.isBiggerThanValue(0)))
        .get()
        .then((list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount));
  }
}
