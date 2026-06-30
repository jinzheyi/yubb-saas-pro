import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/memory_cache_manager.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/disk_cache_manager.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cache_performance_monitor.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cursor_version_store.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';

/// 统一缓存管理器
///
/// 三级缓存查询流程：
/// 1. 查 L1 内存缓存 → 命中则直接返回
/// 2. 查 L2 磁盘缓存 → 命中则填充 L1 并返回
/// 3. 返回 null → 调用方走网络
///
/// 写入流程：
/// 同时写入 L1 + L2（L2 异步写入，不阻塞）
class UnifiedCacheManager {
  final MemoryCacheManager _memoryCache;
  final DiskCacheManager _diskCache;
  final CachePerformanceMonitor _performanceMonitor;
  final CursorVersionStore _cursorVersionStore;

  UnifiedCacheManager({
    required MemoryCacheManager memoryCache,
    required DiskCacheManager diskCache,
    required CursorVersionStore cursorVersionStore,
    CachePerformanceMonitor? performanceMonitor,
  })  : _memoryCache = memoryCache,
        _diskCache = diskCache,
        _cursorVersionStore = cursorVersionStore,
        _performanceMonitor = performanceMonitor ?? CachePerformanceMonitor();

  /// 获取会话列表（三级缓存）
  Future<ConversationCacheResult?> getConversationList(String userId) async {
    // 1. 尝试内存缓存
    final memoryCached = _memoryCache.getConversationList(userId);
    if (memoryCached != null) {
      debugPrint('[UnifiedCache] Conversation list HIT L1 for user: $userId');
      _performanceMonitor.recordConversationListHit();
      return ConversationCacheResult(
        data: memoryCached.data,
        cursorVersion: memoryCached.cursorVersion,
        fromMemory: true,
      );
    }

    // 2. 尝试磁盘缓存
    final diskCached = await _diskCache.getConversationList(userId);
    if (diskCached != null) {
      debugPrint('[UnifiedCache] Conversation list HIT L2 for user: $userId');
      _performanceMonitor.recordConversationListHit();
      
      // 从 CursorVersionStore 获取正确的游标版本
      final cursorVersion = await _cursorVersionStore.getConversationListCursor(userId);
      
      // 回填 L1 内存缓存
      _memoryCache.setConversationList(userId, diskCached, cursorVersion);
      debugPrint('[UnifiedCache] Backfilled L1 cache from L2 for user: $userId');
      
      return ConversationCacheResult(
        data: diskCached,
        cursorVersion: cursorVersion,
        fromMemory: false,
      );
    }

    debugPrint('[UnifiedCache] Conversation list MISS for user: $userId');
    _performanceMonitor.recordConversationListMiss();
    return null;
  }

  /// 设置会话列表缓存
  Future<void> setConversationList(
    String userId,
    List<Conversation> conversations,
    String cursorVersion,
  ) async {
    // 写入 L1
    _memoryCache.setConversationList(userId, conversations, cursorVersion);
    // 异步写入 L2
    await _diskCache.setConversationList(userId, conversations);
  }

  /// 获取消息（三级缓存）
  Future<MessageCacheResult?> getMessages(
    String userId,
    String chatId,
  ) async {
    // 1. 尝试内存缓存
    final memoryCached = _memoryCache.getMessages(userId, chatId);
    if (memoryCached != null) {
      debugPrint('[UnifiedCache] Messages HIT L1 for chat: $chatId');
      _performanceMonitor.recordMessageHit();
      return MessageCacheResult(
        data: memoryCached.data,
        viewportState: memoryCached.viewportState,
        fromMemory: true,
      );
    }

    // 2. 尝试磁盘缓存
    final diskCached = await _diskCache.getMessages(userId, chatId);
    if (diskCached != null) {
      debugPrint('[UnifiedCache] Messages HIT L2 for chat: $chatId');
      _performanceMonitor.recordMessageHit();

      // 回填 L1 内存缓存（包含 viewportState）
      _memoryCache.setMessages(userId, chatId, diskCached.messages, diskCached.viewportState);
      debugPrint('[UnifiedCache] Backfilled L1 cache from L2 for chat: $chatId');

      return MessageCacheResult(
        data: diskCached.messages,
        viewportState: diskCached.viewportState,
        fromMemory: false,
      );
    }

    debugPrint('[UnifiedCache] Messages MISS for chat: $chatId');
    _performanceMonitor.recordMessageMiss();
    return null;
  }

  /// 设置消息缓存
  Future<void> setMessages(
    String userId,
    String chatId,
    List<Message> messages,
    ChatViewportState? viewportState,
  ) async {
    // 写入 L1
    _memoryCache.setMessages(userId, chatId, messages, viewportState);
    // 异步写入 L2（包含 viewportState）
    await _diskCache.setMessages(userId, chatId, messages, viewportState: viewportState);
  }

  /// 清空指定用户的内存缓存（用户登出时调用）
  void clearMemoryCacheForUser(String userId) {
    _memoryCache.clearForUser(userId);
  }

  /// 清空指定会话的消息缓存（clearAll 时调用）
  Future<void> clearMessages(String userId, String chatId) async {
    // 清空 L1
    _memoryCache.clearMessages(userId, chatId);
    // 清空 L2
    await _diskCache.clearMessages(userId, chatId);
  }

  /// 清理过期缓存
  Future<void> cleanup(String userId) async {
    await _diskCache.cleanup(userId);
  }

  /// 输出缓存性能报告（用于调优）
  void reportPerformance() {
    _performanceMonitor.report();
  }
}

/// 会话列表缓存结果
class ConversationCacheResult {
  final List<Conversation> data;
  final String cursorVersion;
  final bool fromMemory;

  const ConversationCacheResult({
    required this.data,
    required this.cursorVersion,
    required this.fromMemory,
  });
}

/// 消息缓存结果
class MessageCacheResult {
  final List<Message> data;
  final ChatViewportState? viewportState;
  final bool fromMemory;

  const MessageCacheResult({
    required this.data,
    this.viewportState,
    required this.fromMemory,
  });
}
