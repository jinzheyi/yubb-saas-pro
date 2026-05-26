import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

// ============================================================
// 类型定义
// ============================================================

/// 会话角标（对应 Protobuf ConversationBadge）
class ConversationBadgeItem {
  const ConversationBadgeItem({required this.chatId, required this.unreadCount});

  final String chatId;
  final int unreadCount;
}

/// 菜单角标（对应 Protobuf MenuBadge）
class MenuBadgeItem {
  const MenuBadgeItem({required this.menuId, required this.badgeCount});

  final String menuId;
  final int badgeCount;
}

// ============================================================
// BadgeState — 不可变状态快照
// ============================================================

class BadgeState {
  const BadgeState({
    this.totalUnreadCount = 0,
    this.conversationBadges = const {},
    this.menuBadges = const {},
    this.lastUpdateTime = 0,
  });

  /// 消息 tab 总未读数（来自后端推送）
  final int totalUnreadCount;

  /// chatId -> 未读数
  final Map<String, int> conversationBadges;

  /// menuId -> 角标数（如 contactsGroupJoinRequest、workbenchTodo）
  final Map<String, int> menuBadges;

  /// 最后更新时间戳（毫秒），用于判断数据是否过期
  final int lastUpdateTime;

  // ====== 派生属性（Tab 栏角标） ======

  /// 消息 tab 角标 = 总未读数
  int get conversationsTabBadge => totalUnreadCount;

  /// 通讯录 tab 角标 = 群组加入申请数
  int get contactsTabBadge => menuBadges['contactsGroupJoinRequest'] ?? 0;

  /// 工作台 tab 角标 = 待办数（预留）
  int get workbenchTabBadge => menuBadges['workbenchTodo'] ?? 0;

  BadgeState copyWith({
    int? totalUnreadCount,
    Map<String, int>? conversationBadges,
    Map<String, int>? menuBadges,
    int? lastUpdateTime,
  }) {
    return BadgeState(
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      conversationBadges: conversationBadges ?? Map.from(this.conversationBadges),
      menuBadges: menuBadges ?? Map.from(this.menuBadges),
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUnreadCount': totalUnreadCount,
      'conversationBadges': conversationBadges,
      'menuBadges': menuBadges,
      'lastUpdateTime': lastUpdateTime,
      'version': _dataVersion,
    };
  }

  factory BadgeState.fromJson(Map<String, dynamic> json) {
    final conv = <String, int>{};
    final rawConv = json['conversationBadges'];
    if (rawConv is Map) {
      rawConv.forEach((k, v) {
        if (k is String && v is int) conv[k] = v;
      });
    }
    final menus = <String, int>{};
    final rawMenus = json['menuBadges'];
    if (rawMenus is Map) {
      rawMenus.forEach((k, v) {
        if (k is String && v is int) menus[k] = v;
      });
    }
    return BadgeState(
      totalUnreadCount: (json['totalUnreadCount'] as num?)?.toInt() ?? 0,
      conversationBadges: conv,
      menuBadges: menus,
      lastUpdateTime: (json['lastUpdateTime'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BadgeState &&
        other.totalUnreadCount == totalUnreadCount &&
        _mapsEqual(other.conversationBadges, conversationBadges) &&
        _mapsEqual(other.menuBadges, menuBadges) &&
        other.lastUpdateTime == lastUpdateTime;
  }

  @override
  int get hashCode =>
      totalUnreadCount.hashCode ^
      Object.hashAll(conversationBadges.entries) ^
      Object.hashAll(menuBadges.entries) ^
      lastUpdateTime.hashCode;

  static const String _dataVersion = '1.0';

  static bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (b[k] != a[k]) return false;
    }
    return true;
  }
}

// ============================================================
// BadgeService — StateNotifier（企业级角标服务）
// ============================================================

class BadgeService extends StateNotifier<BadgeState> {
  BadgeService() : super(const BadgeState()) {
    _loadPersisted();
  }

  static const String _baseUrl = '/system/im/badge/get';
  static const int _dataExpiryMs = 24 * 60 * 60 * 1000; // 24h
  static const int _notifyDebounceMs = 300;
  static const int _saveThrottleMs = 1000;
  static const int _maxConversationBadges = 1000;

  Timer? _notifyDebounceTimer;
  Timer? _saveThrottleTimer;
  bool _hasPendingSave = false;
  bool _syncingFromServer = false;
  int _lastServerSyncAt = 0;

  // ====== 公共 API ======

  /// 从后端 /system/im/badge/get 初始化角标
  /// 认证成功后 / 本地数据过期时调用
  Future<void> initBadgeData(Dio dio) async {
    if (_syncingFromServer) return;
    _syncingFromServer = true;
    _lastServerSyncAt = DateTime.now().millisecondsSinceEpoch;
    try {
      final response = await dio.get(_baseUrl);
      final result = response.data;
      if (result is! Map<String, dynamic>) return;
      // 后端返回 CommonResult<AppImBadgeRespVO> 包装：
      // {"code":0, "data":{"unreadCount":10, "conversationBadges":[...], "menuBadges":[...]}}
      final payload =
          result['data'] as Map<String, dynamic>? ??
          result['result'] as Map<String, dynamic>?;
      if (payload != null) {
        _applySnapshot(payload);
      }
    } catch (_) {
      // 失败时保留本地缓存
    } finally {
      _syncingFromServer = false;
    }
  }

  /// 确保角标数据新鲜（回前台等场景）
  void ensureFresh({int maxAgeMs = 5000}) {
    if (_syncingFromServer) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastServerSyncAt > 0 && (now - _lastServerSyncAt) < maxAgeMs) return;
    // 注意：这里需要 Dio，由调用方处理
  }

  /// 处理 WebSocket badgeUpdated 推送
  void applyWebSocketPayload(Map<String, dynamic> payload) {
    _applySnapshot(payload);
  }

  /// 清空角标（退出登录时调用）
  void reset() {
    state = const BadgeState();
    _hasPendingSave = false;
    _lastServerSyncAt = 0;
    _syncingFromServer = false;
    unawaited(_doPersist());
  }

  /// 获取指定会话角标
  int getConversationBadge(String chatId) {
    return state.conversationBadges[chatId] ?? 0;
  }

  /// 获取指定菜单角标
  int getMenuBadge(String menuId) {
    return state.menuBadges[menuId] ?? 0;
  }

  // ====== 内部实现 ======

  void _applySnapshot(Map<String, dynamic> data) {
    final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 解析会话角标
    // 注意：HTTP API 返回 chatId，WebSocket 推送返回 conversationId
    final convBadges = <String, int>{};
    final rawConv = data['conversationBadges'];
    if (rawConv is List) {
      for (final item in rawConv) {
        if (item is! Map) continue;
        // 兼容 HTTP (chatId) 和 WebSocket (conversationId) 两种字段名
        final chatId = (item['chatId'] ?? item['conversationId'])?.toString().trim() ?? '';
        if (chatId.isEmpty || chatId == '0') continue;
        final count = (item['unreadCount'] as num?)?.toInt() ?? 0;
        convBadges[chatId] = count < 0 ? 0 : count;
      }
    }

    // 解析菜单角标
    final menus = <String, int>{};
    final rawMenus = data['menuBadges'];
    if (rawMenus is List) {
      for (final item in rawMenus) {
        if (item is! Map) continue;
        final menuId = item['menuId']?.toString() ?? '';
        final count = (item['badgeCount'] as num?)?.toInt() ?? 0;
        menus[menuId] = count < 0 ? 0 : count;
      }
    }

    var next = state.copyWith(
      totalUnreadCount: unread < 0 ? 0 : unread,
      conversationBadges: convBadges,
      menuBadges: menus,
      lastUpdateTime: now,
    );

    // 限制会话角标缓存数量
    if (next.conversationBadges.length > _maxConversationBadges) {
      final entries = next.conversationBadges.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final toRemove = next.conversationBadges.length - _maxConversationBadges;
      for (var i = 0; i < toRemove; i++) {
        next.conversationBadges.remove(entries[i].key);
      }
    }

    state = next;
    _debouncedNotify();
    _throttledPersist();
  }

  // ====== 防抖通知 ======

  void _debouncedNotify() {
    _notifyDebounceTimer?.cancel();
    _notifyDebounceTimer = Timer(
      Duration(milliseconds: _notifyDebounceMs),
      () {
        // Riverpod StateNotifier 的 state 赋值已自动触发 UI 更新
        // 此处保留方法用于未来扩展外部监听器
        _notifyDebounceTimer = null;
      },
    );
  }

  // ====== 节流持久化 ======

  void _throttledPersist() {
    _hasPendingSave = true;
    if (_saveThrottleTimer != null) return;
    _doPersist();
    _saveThrottleTimer = Timer(Duration(milliseconds: _saveThrottleMs), () {
      if (_hasPendingSave) _doPersist();
      _saveThrottleTimer = null;
    });
  }

  Future<void> _doPersist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeyRegistry.imBadgeSnapshot,
        jsonEncode(state.toJson()),
      );
      _hasPendingSave = false;
    } catch (_) {}
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeyRegistry.imBadgeSnapshot);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final version = json['version'] as String? ?? '';
        if (version != BadgeState._dataVersion) {
          // 版本不匹配，清除旧数据
          await prefs.remove(StorageKeyRegistry.imBadgeSnapshot);
          return;
        }
        final persisted = BadgeState.fromJson(json);
        // 检查数据是否过期
        final now = DateTime.now().millisecondsSinceEpoch;
        if (persisted.lastUpdateTime > 0 &&
            (now - persisted.lastUpdateTime) > _dataExpiryMs) {
          // 数据过期，不恢复
          return;
        }
        state = persisted;
      }
    } catch (_) {}
  }
}

// ============================================================
// Riverpod Provider
// ============================================================

/// 全局角标状态 Provider
final badgeServiceProvider = StateNotifierProvider<BadgeService, BadgeState>((
  ref,
) {
  return BadgeService();
});
