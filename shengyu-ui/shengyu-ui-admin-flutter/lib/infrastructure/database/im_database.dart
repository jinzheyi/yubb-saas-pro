import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/messages_table.dart';
import 'tables/conversations_table.dart';
import 'tables/call_record_table.dart';
import 'daos/message_dao.dart';
import 'daos/conversation_dao.dart';
import 'daos/call_record_dao.dart';

part 'im_database.g.dart';

/// IM 数据库单例
/// 使用 drift_flutter 初始化，提供数据库连接管理和升级支持
@DriftDatabase(
  tables: [Messages, Conversations, CallRecords],
  daos: [MessageDao, ConversationDao, CallRecordDao],
)
class ImDatabase extends _$ImDatabase {
  ImDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      /// 首次创建数据库时调用
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      /// 数据库升级时调用
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 版本 1 → 2：添加用户隔离、缓存字段、引用信息
          // 使用 columnTransformer 保留旧数据
          await m.alterTable(
            // ignore: experimental_member_use
            TableMigration(
              conversations,
              columnTransformer: {
                conversations.chatId: conversations.chatId,
                conversations.type: conversations.type,
                conversations.targetName: conversations.targetName,
                conversations.targetAvatar: conversations.targetAvatar,
                conversations.targetId: conversations.targetId,
                conversations.lastMessageId: conversations.lastMessageId,
                conversations.lastMessageSequence:
                    conversations.lastMessageSequence,
                conversations.lastReadSequence: conversations.lastReadSequence,
                conversations.lastMessagePreview:
                    conversations.lastMessagePreview,
                conversations.lastMessageType: conversations.lastMessageType,
                conversations.lastMessageSenderName:
                    conversations.lastMessageSenderName,
                conversations.lastMessageIsSelf:
                    conversations.lastMessageIsSelf,
                conversations.lastMessageStatus:
                    conversations.lastMessageStatus,
                conversations.lastMessageHasAtMe:
                    conversations.lastMessageHasAtMe,
                conversations.lastMessageTime: conversations.lastMessageTime,
                conversations.unreadCount: conversations.unreadCount,
                conversations.isPinned: conversations.isPinned,
                conversations.isMuted: conversations.isMuted,
                conversations.updatedAt: conversations.updatedAt,
              },
            ),
          );
          await m.alterTable(
            // ignore: experimental_member_use
            TableMigration(
              messages,
              columnTransformer: {
                messages.messageId: messages.messageId,
                messages.clientMessageId: messages.clientMessageId,
                messages.chatId: messages.chatId,
                messages.type: messages.type,
                messages.status: messages.status,
                messages.content: messages.content,
                messages.senderId: messages.senderId,
                messages.senderName: messages.senderName,
                messages.senderAvatar: messages.senderAvatar,
                messages.sentAt: messages.sentAt,
                messages.sequence: messages.sequence,
                messages.isOutgoing: messages.isOutgoing,
                messages.extraJson: messages.extraJson,
                messages.createdAt: messages.createdAt,
              },
            ),
          );
        }

        if (from < 3) {
          // 版本 2 → 3：添加通话记录表
          await m.createTable(callRecords);
        }

        if (from < 4) {
          // 版本 3 → 4：重建会话表以移除早期版本错误的
          // `UNIQUE(chatId)` 约束。SQLite 实际列名为 `chat_id`，旧约束会让
          // 数据库初始化/升级失败，继而使 IM 本地缓存完全不可用。
          // chat_id 本身已是主键，无需额外唯一约束。
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(conversations));
        }
      },
    );
  }

  static ImDatabase? _instance;

  /// 获取数据库单例
  static ImDatabase get instance {
    _instance ??= ImDatabase(
      driftDatabase(
        name: 'yubb_im',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
    return _instance!;
  }

  /// 关闭数据库连接并重置单例
  static Future<void> disposeInstance() async {
    final current = _instance;
    _instance = null;
    await current?.close();
  }

  /// 清理所有表数据（租户切换时调用）
  Future<void> clearAllTables() async {
    try {
      // 清理消息表（drift 语法）
      await delete(messages).go();

      // 清理会话表（drift 语法）
      await delete(conversations).go();

      // 清理通话记录表（drift 语法）
      await delete(callRecords).go();
    } catch (e) {
      rethrow;
    }
  }
}
