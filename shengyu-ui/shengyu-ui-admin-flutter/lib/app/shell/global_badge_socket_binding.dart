import 'dart:async';

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

final globalBadgeSocketBindingProvider = Provider.autoDispose<
  StreamSubscription<ImSocketEvent>
>((ref) {
  final subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleGlobalBadgeEvent(ref, event));
  ref.onDispose(subscription.cancel);
  return subscription;
});

void _handleGlobalBadgeEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.authSucceeded:
      // 认证成功：通过 HTTP API 初始化角标
      _initBadgeFromServer(ref);
      break;
    case SocketEventTypes.badgeUpdated:
      // WebSocket badge 推送：更新全局角标
      ref.read(badgeServiceProvider.notifier).applyWebSocketPayload(
        event.payload,
      );
      break;
    default:
      break;
  }
}

Future<void> _initBadgeFromServer(Ref ref) async {
  final dio = ref.read(dioProvider);
  await ref.read(badgeServiceProvider.notifier).initBadgeData(dio);
}
