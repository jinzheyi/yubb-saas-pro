import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';

// ============================================================
// 全局角标 Socket 绑定 Provider
//
// 与 conversationRealtimeBindingProvider 不同，此 Provider 在
// app bootstrap 级别被 watch，确保整个应用生命周期内始终监听
// badge 相关 WebSocket 推送，不受页面导航影响。
// ============================================================

// 注意：此处不使用 autoDispose，确保应用全生命周期内始终监听 badge 推送。
// 即使导航到聊天页等非 Tab 页面，角标更新也不会中断。
final globalBadgeSocketBindingProvider = Provider<StreamSubscription<ImSocketEvent>>((ref) {
  final subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleGlobalBadgeEvent(ref, event));
  ref.onDispose(subscription.cancel);
  return subscription;
});

// 角标初始化冷却期：避免频繁请求
int _lastBadgeInitAt = 0;
const int _badgeInitCooldownMs = 10000; // 10秒冷却期

// 标记是否发生了重连：重连后首次 authSucceeded 应强制刷新角标
bool _hasReconnected = false;

void _handleGlobalBadgeEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.authSucceeded:
      // 认证成功：通过 HTTP API 初始化角标
      // 优化：重连后强制刷新（忽略冷却期），确保后台期间角标变化不丢失
      final now = DateTime.now().millisecondsSinceEpoch;
      final shouldForceRefresh = _hasReconnected;
      if (shouldForceRefresh) {
        debugPrint('[GlobalBadge] Reconnected, forcing badge refresh');
        _hasReconnected = false;
        _lastBadgeInitAt = 0; // 重置冷却期，确保立即刷新
      }
      if (now - _lastBadgeInitAt >= _badgeInitCooldownMs) {
        _lastBadgeInitAt = now;
        _initBadgeFromServer(ref);
      }
      break;
    case SocketEventTypes.reconnecting:
      // 记录重连事件，确保重连成功后强制刷新角标
      _hasReconnected = true;
      debugPrint('[GlobalBadge] Reconnecting detected, will force badge refresh on authSucceeded');
      break;
    case SocketEventTypes.badgeUpdated:
      // WebSocket badge 推送：区分增量/全量更新
      final payload = event.payload as Map<String, dynamic>?;
      if (payload != null) {
        final bool incremental = payload['incremental'] == true;
        
        if (incremental) {
          // 增量更新: 合并变化的会话角标
          ref.read(badgeServiceProvider.notifier).applyIncrementalPayload(payload);
        } else {
          // 全量更新: 覆盖所有角标数据
          ref.read(badgeServiceProvider.notifier).applyWebSocketPayload(payload);
        }
      }
      break;
    default:
      break;
  }
}

Future<void> _initBadgeFromServer(Ref ref) async {
  final dio = ref.read(dioProvider);
  await ref.read(badgeServiceProvider.notifier).initBadgeData(dio);
}
