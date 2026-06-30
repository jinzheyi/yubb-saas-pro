import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';

/// 缓存失效策略
enum InvalidationStrategy {
  cursorBased,    // 基于游标版本（会话列表）
  sequenceBased,  // 基于消息序列号（消息列表）
  timeBased,      // 基于时间
}

/// 缓存策略配置
class CachePolicy {
  final Duration memoryTtl;
  final Duration diskTtl;
  final int maxItems;
  final InvalidationStrategy invalidationStrategy;

  const CachePolicy({
    required this.memoryTtl,
    required this.diskTtl,
    required this.maxItems,
    required this.invalidationStrategy,
  });

  /// 会话列表缓存策略
  /// memoryTtl=5min 与 ConversationListPage._foregroundSyncStaleMs(5000ms) 对齐
  static const conversationList = CachePolicy(
    memoryTtl: Duration(minutes: 5),
    diskTtl: Duration(days: 7),
    maxItems: 1000,
    invalidationStrategy: InvalidationStrategy.cursorBased,
  );

  /// 消息缓存策略
  static const messages = CachePolicy(
    memoryTtl: Duration(minutes: 10),
    diskTtl: Duration(days: 30),
    maxItems: 500,
    invalidationStrategy: InvalidationStrategy.sequenceBased,
  );
}

/// 消息缓存条目
class MessageCacheEntry {
  final List<Message> data;
  final ChatViewportState? viewportState;
  final DateTime timestamp;

  const MessageCacheEntry({
    required this.data,
    this.viewportState,
    required this.timestamp,
  });

  /// 是否已过期
  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}
