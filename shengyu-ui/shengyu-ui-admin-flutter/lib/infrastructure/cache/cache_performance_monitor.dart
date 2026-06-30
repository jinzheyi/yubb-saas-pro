import 'package:flutter/foundation.dart';

/// 缓存性能监控
///
/// 记录缓存命中/未命中次数，计算命中率
/// 用于调优缓存策略
class CachePerformanceMonitor {
  int _conversationListHits = 0;
  int _conversationListMisses = 0;
  int _messageHits = 0;
  int _messageMisses = 0;

  void recordConversationListHit() => _conversationListHits++;
  void recordConversationListMiss() => _conversationListMisses++;
  void recordMessageHit() => _messageHits++;
  void recordMessageMiss() => _messageMisses++;

  double get conversationListHitRate {
    final total = _conversationListHits + _conversationListMisses;
    if (total == 0) return 0.0;
    return _conversationListHits / total;
  }

  double get messageHitRate {
    final total = _messageHits + _messageMisses;
    if (total == 0) return 0.0;
    return _messageHits / total;
  }

  void report() {
    debugPrint('[CacheMonitor] ConversationList: '
        '${(conversationListHitRate * 100).toStringAsFixed(1)}% '
        '($_conversationListHits/${_conversationListHits + _conversationListMisses})');
    debugPrint('[CacheMonitor] Messages: '
        '${(messageHitRate * 100).toStringAsFixed(1)}% '
        '($_messageHits/${_messageHits + _messageMisses})');
  }

  void reset() {
    _conversationListHits = 0;
    _conversationListMisses = 0;
    _messageHits = 0;
    _messageMisses = 0;
  }
}
