import 'package:drift/drift.dart';

import '../im_database.dart';
import '../tables/call_record_table.dart';

part 'call_record_dao.g.dart';

/// 通话记录 DAO
///
/// 提供通话记录的本地缓存 CRUD 操作，支持：
/// - 按会话查询通话记录
/// - 按用户查询通话记录
/// - 插入/更新通话记录
/// - 用户切换时清理数据
@DriftAccessor(tables: [CallRecords])
class CallRecordDao extends DatabaseAccessor<ImDatabase> with _$CallRecordDaoMixin {
  CallRecordDao(ImDatabase db) : super(db);

  /// 按会话ID查询通话记录（按时间倒序）
  Future<List<CallRecordData>> getRecordsByChatId(String chatId, {int limit = 50}) {
    return (select(callRecords)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(limit))
        .get();
  }

  /// 按用户ID查询通话记录（按时间倒序）
  Future<List<CallRecordData>> getRecordsByUserId(String userId, {int limit = 50}) {
    return (select(callRecords)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(limit))
        .get();
  }

  /// 查询单条通话记录
  Future<CallRecordData?> getRecordByCallId(String callId) {
    return (select(callRecords)
          ..where((t) => t.callId.equals(callId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 插入或更新通话记录
  Future<void> upsertRecord(CallRecordsCompanion record) async {
    await into(callRecords).insertOnConflictUpdate(record);
  }

  /// 批量插入或更新通话记录
  Future<void> upsertRecords(List<CallRecordsCompanion> records) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(callRecords, records);
    });
  }

  /// 删除指定会话的所有通话记录
  Future<int> deleteByChatId(String chatId) async {
    return (delete(callRecords)
          ..where((t) => t.chatId.equals(chatId)))
        .go();
  }

  /// 清理所有通话记录（用户切换时调用）
  Future<void> deleteAll() async {
    await delete(callRecords).go();
  }

  /// 查询通话记录总数
  Future<int> countRecords() async {
    final result = await customSelect('SELECT COUNT(*) AS cnt FROM call_records')
        .getSingle();
    return result.read<int>('cnt');
  }
}
