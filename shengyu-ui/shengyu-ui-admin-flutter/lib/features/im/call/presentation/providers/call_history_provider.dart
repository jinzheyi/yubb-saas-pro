import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';

/// 通话记录列表 Provider
/// 
/// 支持按通话类型和时间范围筛选
final callHistoryProvider = StateNotifierProvider.family<CallHistoryNotifier, AsyncValue<List<CallRecord>>, CallHistoryFilter>((ref, filter) {
  return CallHistoryNotifier(ref, filter);
});

/// 通话记录筛选参数
class CallHistoryFilter {
  final int? filterType;
  final DateTimeRange? dateRange;

  const CallHistoryFilter({
    this.filterType,
    this.dateRange,
  });

  CallHistoryFilter copyWith({
    int? filterType,
    DateTimeRange? dateRange,
  }) {
    return CallHistoryFilter(
      filterType: filterType ?? this.filterType,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallHistoryFilter &&
        other.filterType == filterType &&
        other.dateRange?.start == dateRange?.start &&
        other.dateRange?.end == dateRange?.end;
  }

  @override
  int get hashCode => Object.hash(filterType, dateRange?.start, dateRange?.end);
}

class CallHistoryNotifier extends StateNotifier<AsyncValue<List<CallRecord>>> {
  CallHistoryNotifier(this.ref, this.filter) : super(const AsyncValue.data([])) {
    _loadRecords();
  }

  final Ref ref;
  final CallHistoryFilter filter;

  /// 加载通话记录
  Future<void> _loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(callRepositoryProvider);
      final records = await repository.getCallRecords(
        callType: filter.filterType,
        startTime: filter.dateRange?.start,
        endTime: filter.dateRange?.end,
        pageNo: 1,
        pageSize: 100, // 加载最近100条
      );
      state = AsyncValue.data(records);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadRecords();
  }
}
