import 'package:flutter/widgets.dart';

/// LRU 缓存管理的 GlobalKey 集合，限制缓存大小，避免随消息数量无限增长
class MessageKeyCache {
  MessageKeyCache({int maxSize = 100}) : _maxSize = maxSize;

  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};
  final List<String> _accessOrder = <String>[];
  final int _maxSize;

  GlobalKey get(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
    return _keys.putIfAbsent(key, GlobalKey.new);
  }

  GlobalKey? operator [](String key) => _keys[key];

  void putIfAbsent(String key, GlobalKey Function() ifAbsent) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
    _keys.putIfAbsent(key, ifAbsent);
  }

  /// 回收超出限制的旧 Key
  void evict() {
    while (_keys.length > _maxSize && _accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      _keys.remove(oldest);
    }
  }

  void clear() {
    _keys.clear();
    _accessOrder.clear();
  }

  int get length => _keys.length;
}
