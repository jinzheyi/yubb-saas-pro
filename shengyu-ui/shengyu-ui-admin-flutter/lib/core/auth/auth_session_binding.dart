import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_refresh_service.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';

final authSessionBindingProvider = Provider<void>((ref) {
  final StreamSubscription<ImSocketEvent> subscription = ref
      .read(socketMessageDispatcherProvider)
      .stream
      .listen((event) => _handleSessionEvent(ref, event));
  ref.onDispose(subscription.cancel);
});

void _handleSessionEvent(Ref ref, ImSocketEvent event) {
  switch (event.type) {
    case SocketEventTypes.sessionInvalidated:
    case SocketEventTypes.sessionKicked:
    case SocketEventTypes.sessionLoggedOut:
    case SocketEventTypes.sessionRevoked:
    case SocketEventTypes.sessionReauthRequired:
      unawaited(ref.read(imSocketClientProvider).disconnect());
      unawaited(ref.read(authSessionProvider.notifier).clearSession());
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
  }
}
