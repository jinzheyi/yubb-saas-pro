import 'package:drift/drift.dart';

/// 通话记录表定义
///
/// 使用 @DataClassName 避免与 Domain Entity (CallRecord) 命名冲突
/// Drift 生成的数据类名为 CallRecordData，用于数据库操作
@TableIndex(name: 'idx_call_records_chat_id', columns: {#chatId})
@TableIndex(name: 'idx_call_records_user_id', columns: {#userId})
@TableIndex(name: 'idx_call_records_start_time', columns: {#startTime})
@TableIndex(name: 'idx_call_records_call_id', columns: {#callId}, unique: true)
@DataClassName('CallRecordData')
class CallRecords extends Table {
  /// 通话ID（主键）
  TextColumn get callId => text()();

  /// 会话ID
  TextColumn get chatId => text()();

  /// 通话类型（1-语音 2-视频）
  IntColumn get callType => integer()();

  /// 通话状态（1-已接通 2-未接听 3-已拒绝 4-忙线 5-已取消）
  IntColumn get status => integer()();

  /// 通话时长（秒）
  IntColumn get duration => integer().withDefault(const Constant(0))();

  /// 主叫用户ID
  TextColumn get callerId => text()();

  /// 被叫用户ID
  TextColumn get calleeId => text()();

  /// 主叫昵称（冗余字段）
  TextColumn get callerName => text().nullable()();

  /// 主叫头像（冗余字段）
  TextColumn get callerAvatar => text().nullable()();

  /// 被叫昵称（冗余字段）
  TextColumn get calleeName => text().nullable()();

  /// 被叫头像（冗余字段）
  TextColumn get calleeAvatar => text().nullable()();

  /// 通话开始时间
  DateTimeColumn get startTime => dateTime()();

  /// 通话结束时间
  DateTimeColumn get endTime => dateTime().nullable()();

  /// 是否为主叫方
  BoolColumn get isCaller => boolean()();

  /// 用户隔离字段
  TextColumn get userId => text().withDefault(const Constant(''))();

  /// 缓存时间戳（毫秒级）
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {callId};
}
