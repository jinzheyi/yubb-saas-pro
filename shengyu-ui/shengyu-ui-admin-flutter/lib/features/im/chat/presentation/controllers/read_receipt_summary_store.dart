import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_summary_store_state.dart';

class ReadReceiptSummaryStore
    extends StateNotifier<ReadReceiptSummaryStoreState> {
  ReadReceiptSummaryStore(this._messageRepository)
    : super(const ReadReceiptSummaryStoreState());

  static const Duration ttl = Duration(minutes: 10);
  static const int cacheMax = 200;
  static const Duration prefetchDebounce = Duration(milliseconds: 250);
  static const int prefetchBatchLimit = 5;

  final MessageRepository _messageRepository;
  final Set<String> _inFlight = <String>{};
  Timer? _prefetchTimer;
  String _lastPrefetchKey = '';

  ReadReceiptSummary? getSummary(String messageId) {
    final normalized = messageId.trim();
    if (!_isServerMessageId(normalized)) {
      return null;
    }
    return state.entries[normalized]?.summary;
  }

  bool hasFreshSummary(String messageId) {
    final normalized = messageId.trim();
    if (!_isServerMessageId(normalized)) {
      return false;
    }
    final entry = state.entries[normalized];
    if (entry == null) {
      return false;
    }
    return DateTime.now().difference(entry.fetchedAt) <= ttl;
  }

  Future<ReadReceiptSummary?> ensureSummary(String messageId) async {
    final normalized = messageId.trim();
    if (!_isServerMessageId(normalized)) {
      return null;
    }
    final cached = state.entries[normalized];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) <= ttl) {
      return cached.summary;
    }
    if (_inFlight.contains(normalized)) {
      return cached?.summary;
    }
    _inFlight.add(normalized);
    try {
      final summary = await _messageRepository.getReadReceiptSummary(
        messageId: normalized,
      );
      _putSummary(normalized, summary);
      return summary;
    } finally {
      _inFlight.remove(normalized);
    }
  }

  Future<void> prefetchSummaries(List<String> messageIds) async {
    final candidates = <String>[];
    for (final rawId in messageIds.reversed) {
      final messageId = rawId.trim();
      if (!_isServerMessageId(messageId) || candidates.contains(messageId)) {
        continue;
      }
      if (hasFreshSummary(messageId) || _inFlight.contains(messageId)) {
        continue;
      }
      candidates.add(messageId);
      if (candidates.length >= prefetchBatchLimit) {
        break;
      }
    }
    final orderedIds = candidates.reversed.toList(growable: false);
    final nextKey = orderedIds.join(',');
    if (nextKey.isEmpty || nextKey == _lastPrefetchKey) {
      return;
    }
    _lastPrefetchKey = nextKey;
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(prefetchDebounce, () {
      unawaited(_loadBatch(orderedIds));
    });
  }

  void invalidate(String messageId) {
    final normalized = messageId.trim();
    if (!_isServerMessageId(normalized) ||
        !state.entries.containsKey(normalized)) {
      return;
    }
    final nextEntries = Map<String, ReadReceiptSummaryCacheEntry>.from(
      state.entries,
    )..remove(normalized);
    state = state.copyWith(entries: nextEntries);
  }

  void hydrate(ReadReceiptSummary? summary) {
    if (summary == null || !_isServerMessageId(summary.messageId.trim())) {
      return;
    }
    _putSummary(summary.messageId.trim(), summary);
  }

  void disposeTimer() {
    _prefetchTimer?.cancel();
  }

  Future<void> refresh(String messageId) async {
    invalidate(messageId);
    await ensureSummary(messageId);
  }

  Future<void> _loadBatch(List<String> messageIds) async {
    if (messageIds.isEmpty) {
      return;
    }
    final targets = <String>[];
    for (final messageId in messageIds) {
      if (_inFlight.contains(messageId) || hasFreshSummary(messageId)) {
        continue;
      }
      _inFlight.add(messageId);
      targets.add(messageId);
    }
    if (targets.isEmpty) {
      return;
    }
    try {
      final summaries = await _messageRepository.getReadReceiptSummaries(
        messageIds: targets,
      );
      final summaryMap = <String, ReadReceiptSummary>{
        for (final summary in summaries) summary.messageId.trim(): summary,
      };
      for (final messageId in targets) {
        _putSummary(messageId, summaryMap[messageId]);
      }
    } catch (_) {
      for (final messageId in targets) {
        _inFlight.remove(messageId);
      }
      rethrow;
    } finally {
      for (final messageId in targets) {
        _inFlight.remove(messageId);
      }
    }
  }

  void _putSummary(String messageId, ReadReceiptSummary? summary) {
    final nextEntries = Map<String, ReadReceiptSummaryCacheEntry>.from(
      state.entries,
    );
    nextEntries[messageId] = ReadReceiptSummaryCacheEntry(
      summary: summary,
      fetchedAt: DateTime.now(),
    );
    state = state.copyWith(entries: _prune(nextEntries));
  }

  Map<String, ReadReceiptSummaryCacheEntry> _prune(
    Map<String, ReadReceiptSummaryCacheEntry> entries,
  ) {
    final now = DateTime.now();
    final kept =
        entries.entries
            .where((entry) => now.difference(entry.value.fetchedAt) <= ttl)
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.value.fetchedAt.compareTo(left.value.fetchedAt),
          );
    return <String, ReadReceiptSummaryCacheEntry>{
      for (final entry in kept.take(cacheMax)) entry.key: entry.value,
    };
  }

  @override
  void dispose() {
    _prefetchTimer?.cancel();
    super.dispose();
  }

  /// 读回执 REST 接口的 messageId 参数是后端雪花 ID（Long）。
  /// 客户端发送中的临时消息使用 UUID，不能作为该接口的查询参数。
  static bool _isServerMessageId(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0;
  }
}
