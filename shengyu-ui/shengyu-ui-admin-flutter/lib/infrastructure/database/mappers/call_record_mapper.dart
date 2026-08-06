import 'package:drift/drift.dart';

import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import '../im_database.dart' show CallRecordData, CallRecordsCompanion;

/// 通话记录 Mapper
///
/// 在 Domain Entity (CallRecord) 和 Drift 数据模型之间转换。
/// 遵循 Clean Architecture 分层原则：
/// - Domain 层：纯业务实体，不依赖框架
/// - Infrastructure 层：Drift 数据库模型（CallRecordData / CallRecordsCompanion）
/// - Mapper：负责两者之间的数据转换
///
/// 注意：CallRecordData 和 CallRecordsCompanion 由 Drift build_runner 生成。
class CallRecordMapper {
  /// Drift Data Class → Domain Entity
  static CallRecord toDomain(CallRecordData data) {
    return CallRecord(
      callId: data.callId,
      chatId: data.chatId,
      callType: data.callType,
      status: data.status,
      duration: data.duration,
      callerId: data.callerId,
      calleeId: data.calleeId,
      callerName: data.callerName,
      callerAvatar: data.callerAvatar,
      calleeName: data.calleeName,
      calleeAvatar: data.calleeAvatar,
      startTime: data.startTime,
      endTime: data.endTime,
      isCaller: data.isCaller,
    );
  }

  /// Domain Entity → Drift Companion (用于插入/更新)
  static CallRecordsCompanion toCompanion(
    CallRecord entity, {
    required String userId,
    required int cachedAt,
  }) {
    return CallRecordsCompanion(
      callId: Value(entity.callId),
      chatId: Value(entity.chatId),
      callType: Value(entity.callType),
      status: Value(entity.status),
      duration: Value(entity.duration),
      callerId: Value(entity.callerId),
      calleeId: Value(entity.calleeId),
      callerName: Value(entity.callerName),
      callerAvatar: Value(entity.callerAvatar),
      calleeName: Value(entity.calleeName),
      calleeAvatar: Value(entity.calleeAvatar),
      startTime: Value(entity.startTime),
      endTime: Value(entity.endTime),
      isCaller: Value(entity.isCaller),
      userId: Value(userId),
      cachedAt: Value(cachedAt),
    );
  }

  /// 批量转换：Drift → Domain
  static List<CallRecord> toDomainList(List<CallRecordData> dataList) {
    return dataList.map(toDomain).toList();
  }

  /// 批量转换：Domain → Drift Companion
  static List<CallRecordsCompanion> toCompanionList(
    List<CallRecord> entities, {
    required String userId,
    required int cachedAt,
  }) {
    return entities
        .map((e) => toCompanion(e, userId: userId, cachedAt: cachedAt))
        .toList();
  }
}
