import 'dart:collection';

/// 会话预览缓存条目（存储预览 token 数据）
class PreviewCacheEntry {
  const PreviewCacheEntry({required this.tokens, required this.isNoticeFlags});

  /// 预览 token 文本列表
  final List<String> tokens;

  /// 对应的 isNotice 标记列表
  final List<bool> isNoticeFlags;
}

/// 会话预览文本缓存
///
/// 采用 LRU（最近最少使用）策略，最大缓存 200 条。
/// 缓存 key 由 chatId + previewVersion 组成，当会话的 lastMessageId、
/// lastMessagePreview 或 unreadCount 发生变化时，previewVersion 也会变化，
/// 从而自动失效旧缓存。
class ConversationPreviewCache {
  ConversationPreviewCache._();

  static final ConversationPreviewCache instance = ConversationPreviewCache._();

  /// 最大缓存条目数
  static const int _maxSize = 200;

  /// LinkedHashMap 维持插入顺序，用于实现 LRU 淘汰
  // ignore: prefer_collection_literals
  final _cache = LinkedHashMap<String, PreviewCacheEntry>();

  /// 获取缓存的预览结果
  ///
  /// 返回 null 表示缓存未命中。
  PreviewCacheEntry? get(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null) {
      return null;
    }
    // 访问后将条目移至末尾（最近使用）
    _cache.remove(cacheKey);
    _cache[cacheKey] = entry;
    return entry;
  }

  /// 存入预览结果到缓存
  ///
  /// 如果缓存已满，淘汰最久未使用的条目。
  void put(String cacheKey, PreviewCacheEntry entry) {
    // 如果 key 已存在，先移除以更新访问顺序
    _cache.remove(cacheKey);
    // 淘汰策略
    while (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = entry;
  }

  /// 手动清理指定 key 的缓存
  void evict(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// 清空所有缓存
  void evictAll() {
    _cache.clear();
  }

  /// 当前缓存条目数（仅供调试）
  int get length => _cache.length;
}
