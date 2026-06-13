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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      /// 首次创建数据库时调用
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      /// 数据库升级时调用
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本升级时，根据 from 版本号执行对应的迁移逻辑
        // 示例:
        // if (from < 2) {
        //   await m.alterTable(TableMigration(...));
        // }
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
