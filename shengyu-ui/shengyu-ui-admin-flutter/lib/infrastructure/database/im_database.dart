import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/messages_table.dart';
import 'tables/conversations_table.dart';
import 'daos/message_dao.dart';
import 'daos/conversation_dao.dart';

part 'im_database.g.dart';

/// IM 数据库单例
/// 使用 drift_flutter 初始化，提供数据库连接管理和升级支持
@DriftDatabase(
  tables: [Messages, Conversations],
  daos: [MessageDao, ConversationDao],
)
class ImDatabase extends _$ImDatabase {
  ImDatabase(super.e);

  @override
  int get schemaVersion => 2;

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
            TableMigration(
              conversations,
              columnTransformer: {
                conversations.chatId: conversations.chatId,
                conversations.type: conversations.type,
                conversations.targetName: conversations.targetName,
                conversations.targetAvatar: conversations.targetAvatar,
                conversations.targetId: conversations.targetId,
                conversations.lastMessageId: conversations.lastMessageId,
                conversations.lastMessageSequence: conversations.lastMessageSequence,
                conversations.lastReadSequence: conversations.lastReadSequence,
                conversations.lastMessagePreview: conversations.lastMessagePreview,
                conversations.lastMessageType: conversations.lastMessageType,
                conversations.lastMessageSenderName: conversations.lastMessageSenderName,
                conversations.lastMessageIsSelf: conversations.lastMessageIsSelf,
                conversations.lastMessageStatus: conversations.lastMessageStatus,
                conversations.lastMessageHasAtMe: conversations.lastMessageHasAtMe,
                conversations.lastMessageTime: conversations.lastMessageTime,
                conversations.unreadCount: conversations.unreadCount,
                conversations.isPinned: conversations.isPinned,
                conversations.isMuted: conversations.isMuted,
                conversations.updatedAt: conversations.updatedAt,
              },
            ),
          );
          await m.alterTable(
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
      },
    );
  }

  static ImDatabase? _instance;

  /// 获取数据库单例
  static ImDatabase get instance {
    _instance ??= ImDatabase(driftDatabase(name: 'yubb_im'));
    return _instance!;
  }

  /// 关闭数据库连接并重置单例
  static Future<void> disposeInstance() async {
    final current = _instance;
    _instance = null;
    await current?.close();
  }
}
