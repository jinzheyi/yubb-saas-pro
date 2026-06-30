import 'dart:collection';

import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cache_policy.dart';

/// 内存缓存管理器
///
/// 设计要点：
/// 1. 使用 LinkedHashMap 实现 LRU 淘汰
/// 2. 按 userId 隔离缓存
/// 3. 会话列表全局一份（每个用户），消息按 chatId 分片
class MemoryCacheManager {
  // 会话列表缓存: key=userId, value=_ConversationCacheEntry
  final LinkedHashMap<String, _ConversationCacheEntry> _conversationCache =
      LinkedHashMap<String, _ConversationCacheEntry>();

  // 消息缓存: key=userId:chatId, value=_MessageCacheEntry
  final LinkedHashMap<String, _MessageCacheEntry> _messageCache =
      LinkedHashMap<String, _MessageCacheEntry>();

  // 消息缓存容量上限
  static const int _maxMessageCacheEntries = 50;

  /// 获取会话列表缓存
  _ConversationCacheEntry? getConversationList(String userId) {
    final entry = _conversationCache[userId];
    if (entry == null) return null;
    if (entry.isExpired(CachePolicy.conversationList.memoryTtl)) {
      _conversationCache.remove(userId);
      return null;
    }
    // 移动到最近使用（LRU）
    _conversationCache.remove(userId);
    _conversationCache[userId] = entry;
    return entry;
  }

  /// 设置会话列表缓存
  void setConversationList(
    String userId,
    List<Conversation> conversations,
    String cursorVersion,
  ) {
    _conversationCache[userId] = _ConversationCacheEntry(
      data: conversations,
      cursorVersion: cursorVersion,
      timestamp: DateTime.now(),
    );
  }

  /// 获取消息缓存
  _MessageCacheEntry? getMessages(String userId, String chatId) {
    final key = '$userId:$chatId';
    final entry = _messageCache[key];
    if (entry == null) return null;
    if (entry.isExpired(CachePolicy.messages.memoryTtl)) {
      _messageCache.remove(key);
      return null;
    }
    // 移动到最近使用（LRU）
    _messageCache.remove(key);
    _messageCache[key] = entry;
    return entry;
  }

  /// 设置消息缓存
  void setMessages(
    String userId,
    String chatId,
    List<Message> messages,
    ChatViewportState? viewportState,
  ) {
    final key = '$userId:$chatId';
    _messageCache.remove(key); // 先移除再添加（LRU 顺序）
    _messageCache[key] = _MessageCacheEntry(
      data: messages,
      viewportState: viewportState,
      timestamp: DateTime.now(),
    );

    // LRU 淘汰
    while (_messageCache.length > _maxMessageCacheEntries) {
      final oldestKey = _messageCache.keys.first;
      _messageCache.remove(oldestKey);
    }
  }

  /// 清空指定用户的内存缓存（用户登出时调用）
  void clearForUser(String userId) {
    _conversationCache.remove(userId);
    final keysToRemove =
        _messageCache.keys.where((k) => k.startsWith('$userId:')).toList();
    for (final key in keysToRemove) {
      _messageCache.remove(key);
    }
  }

  /// 清空指定会话的消息缓存（clearAll 时调用）
  void clearMessages(String userId, String chatId) {
    final key = '$userId:$chatId';
    _messageCache.remove(key);
  }

  /// 清空所有缓存
  void clearAll() {
    _conversationCache.clear();
    _messageCache.clear();
  }
}

class _ConversationCacheEntry {
  final List<Conversation> data;
  final String cursorVersion;
  final DateTime timestamp;

  _ConversationCacheEntry({
    required this.data,
    required this.cursorVersion,
    required this.timestamp,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class _MessageCacheEntry {
  final List<Message> data;
  final ChatViewportState? viewportState;
  final DateTime timestamp;

  _MessageCacheEntry({
    required this.data,
    this.viewportState,
    required this.timestamp,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}
