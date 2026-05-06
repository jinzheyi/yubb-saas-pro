import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';

final socketSessionCoordinatorProvider = Provider<void>((ref) {
  final coordinator = SocketSessionCoordinator(
    ref.read(imSocketClientProvider),
  );
  ref.listen<AuthSession>(
    authSessionProvider,
    coordinator.onSessionChanged,
    fireImmediately: true,
  );
});

class SocketSessionCoordinator {
  SocketSessionCoordinator(this._socketClient);

  final ImSocketClient _socketClient;
  Future<void> _serial = Future<void>.value();

  void onSessionChanged(AuthSession? previous, AuthSession next) {
    _serial = _serial.then((_) => _syncSession(previous, next));
  }

  Future<void> waitForIdle() => _serial;

  Future<void> _syncSession(AuthSession? previous, AuthSession next) async {
    final previousSession = previous ?? const AuthSession.anonymous();

    if (!next.isAuthenticated) {
      if (previousSession.isAuthenticated ||
          _socketClient.state != ImSocketConnectionState.disconnected) {
        await _socketClient.disconnect();
      }
      return;
    }

    if (!previousSession.isAuthenticated) {
      await _socketClient.connect();
      await _socketClient.auth(next);
      return;
    }

    if (previousSession.accessToken != next.accessToken) {
      await _socketClient.reauth(next);
      return;
    }

    if (_socketClient.state == ImSocketConnectionState.disconnected ||
        _socketClient.state == ImSocketConnectionState.invalidated) {
      await _socketClient.connect();
      await _socketClient.auth(next);
    }
  }
}
