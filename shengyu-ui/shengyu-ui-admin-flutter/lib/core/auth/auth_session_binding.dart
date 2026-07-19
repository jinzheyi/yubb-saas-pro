import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_refresh_service.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';

final authSessionBindingProvider = Provider<void>((ref) {
  ref.watch(sessionCleanupServiceProvider);
  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleSessionEvent(ref, event));
  ref.onDispose(subscription.cancel);
});

void _handleSessionEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.sessionInvalidated:
    case SocketEventTypes.sessionLoggedOut:
    case SocketEventTypes.sessionRevoked:
    case SocketEventTypes.sessionReauthRequired:
      unawaited(ref.read(imSocketClientProvider).disconnect());
      unawaited(ref.read(authSessionProvider.notifier).clearSession());
      ref.read(sessionCleanupServiceProvider).forceClearAllUserScopes();
      break;
    case SocketEventTypes.sessionKicked:
      // 被踢出事件由 AppShell 监听并显示弹窗，用户确认后才执行登出
      // 此处不执行任何操作，避免与弹窗逻辑冲突
      break;
    case SocketEventTypes.tokenRenewSuggested:
      unawaited(_refreshSession(ref));
      break;
    default:
      break;
  }
}

Future<void> _refreshSession(Ref ref) async {
  try {
    await ref
        .read(refreshTokenCoordinatorProvider)
        .refresh(
          () => ref.read(authRefreshServiceProvider).refreshCurrentSession(),
        );
  } catch (_) {
    await ref.read(imSocketClientProvider).disconnect();
    await ref.read(authSessionProvider.notifier).clearSession();
    ref.read(sessionCleanupServiceProvider).forceClearAllUserScopes();
  }
}
