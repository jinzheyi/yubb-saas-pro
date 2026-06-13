import 'dart:collection';

/// 消息去重器，基于 LRU（最近最少使用）缓存策略。
///
/// 用于防止 WebSocket 推送的重复消息导致界面重复渲染。
/// 支持三种去重 key：messageId / clientMessageId / sequence。
class MessageDeduplicator {
  /// 创建去重器实例
  /// [maxSize] 缓存最大容量，默认 1000
  MessageDeduplicator({this.maxSize = 1000}) : assert(maxSize > 0);

  /// 缓存最大容量
  final int maxSize;

  // 使用 LinkedHashMap 保持插入顺序，淘汰最早加入的条目实现 LRU
  final LinkedHashMap<String, int> _cache = LinkedHashMap<String, int>();

  /// 检查消息是否为重复消息
  ///
  /// 返回 true 表示该消息已存在（重复），调用方应跳过处理。
  /// 返回 false 表示该消息是新的，已自动加入缓存。
  ///
  /// 去重优先级：messageId > clientMessageId > sequence
  bool isDuplicate(Map<String, dynamic> rawMessage) {
    final key = _extractDedupKey(rawMessage);
    if (key == null) {
      // 无法提取去重 key 的消息不做去重，直接放行
      return false;
    }

    if (_cache.containsKey(key)) {
      return true; // 已存在，判定为重复
    }

    _addKey(key);
    return false; // 新消息
  }

  /// 清理指定 chatId 关联的所有去重缓存
  /// 适用于聊天窗口关闭时的资源清理
  void clearByChatId(String chatId) {
    _cache.removeWhere((key, _) =>
      key.startsWith('m:$chatId:') ||  // messageId prefix
      key.startsWith('cm:$chatId:') || // clientMessageId prefix
      key.startsWith('s:$chatId:'));   // sequence prefix
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
  }

  /// 当前缓存条目数量
  int get size => _cache.length;

  /// 添加去重 key，超出容量时淘汰最早加入的条目
  void _addKey(String key) {
    if (_cache.length >= maxSize) {
      // LinkedHashMap 的 first 即为最早插入的条目，淘汰它
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = 1;
  }

  /// 从原始消息 Map 中提取去重 key
  ///
  /// 优先级顺序：
  /// 1. messageId（服务端生成的唯一 ID）
  /// 2. clientMessageId（客户端生成的唯一 ID）
  /// 3. sequence（消息序列号）
  String? _extractDedupKey(Map<String, dynamic> raw) {
    final messageId = _trim(raw['messageId']);
    final clientMessageId = _trim(raw['clientMessageId']);
    final sequence = _trim(raw['sequence']);

    // 优先使用 messageId
    if (messageId != null && messageId.isNotEmpty && messageId != '0') {
      final chatId = _trim(raw['chatId']) ?? _trim(raw['conversationId']) ?? '';
      return 'm:$chatId:$messageId';
    }

    // 其次使用 clientMessageId
    if (clientMessageId != null &&
        clientMessageId.isNotEmpty &&
        clientMessageId != '0') {
      final chatId = _trim(raw['chatId']) ?? _trim(raw['conversationId']) ?? '';
      return 'cm:$chatId:$clientMessageId';
    }

    // 最后使用 sequence
    if (sequence != null && sequence.isNotEmpty && sequence != '0') {
      final chatId = _trim(raw['chatId']) ?? _trim(raw['conversationId']) ?? '';
      return 's:$chatId:$sequence';
    }

    return null;
  }

  String? _trim(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
