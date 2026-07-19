import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_state.dart';

final socketSessionCoordinatorProvider = Provider<SocketSessionCoordinator>((ref) {
  final coordinator = SocketSessionCoordinator(
    ref.read(imSocketClientProvider),
  );
  ref.listen<AuthSession>(
    authSessionProvider,
    coordinator.onSessionChanged,
    fireImmediately: true,
  );
  return coordinator;
});

class SocketSessionCoordinator {
  SocketSessionCoordinator(this._socketClient);

  final ImSocketClient _socketClient;
  Future<void> _serial = Future<void>.value();
  int _chainLength = 0;

  void onSessionChanged(AuthSession? previous, AuthSession next) {
    _enqueue(() => _syncSession(previous, next));
  }

  Future<void> waitForIdle() => _serial;

  /// 入队任务，限制链长度 + 异常隔离（防止无限增长和异常传播）
  Future<void> _enqueue(Future<void> Function() task) async {
    _serial = _serial.then((_) async {
      try {
        await task();
      } catch (e, st) {
        debugPrint('[SocketSessionCoordinator] task error: $e\n$st');
      }
    }).catchError((Object e) {
      debugPrint('[SocketSessionCoordinator] catchError: $e');
    });

    // 链长度限制：超过 100 个任务后等待并重置
    if (_chainLength++ > 100) {
      await _serial;
      _serial = Future.value();
      _chainLength = 0;
    }
  }

  Future<void> _syncSession(AuthSession? previous, AuthSession next) async {
    final previousSession = previous ?? AuthSession.anonymous();

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

  bool _isStale = false;

  /// 通知 App 进入后台
  void notifyAppBackgrounded() {
    debugPrint('[SocketSessionCoordinator] app backgrounded, marking connection stale');
    // 标记连接为 stale，但不立即断开
    // 这样回到前台时可以快速检测是否需要重连
    _isStale = true;
  }

  /// 强制重连
  void forceReconnect() {
    debugPrint('[SocketSessionCoordinator] force reconnect');
    // 断开当前连接，重新建立
    _serial = _serial.then((_) => _forceReconnectInternal());
  }

  /// 检查连接是否 stale 并决定是否重连
  void checkAndReconnectIfStale() {
    debugPrint('[SocketSessionCoordinator] checking connection staleness');
    if (_isStale) {
      _isStale = false;
      forceReconnect();
    } else {
      debugPrint('[SocketSessionCoordinator] connection is fresh, no reconnect needed');
    }
  }

  Future<void> _forceReconnectInternal() async {
    try {
      _isStale = false;
      // 如果当前已连接，先断开
      if (_socketClient.state != ImSocketConnectionState.disconnected) {
        await _socketClient.disconnect();
      }
      // 重新连接
      await _socketClient.connect();
      debugPrint('[SocketSessionCoordinator] force reconnect completed');
    } catch (e, st) {
      debugPrint('[SocketSessionCoordinator] force reconnect error: $e\n$st');
    }
  }
}
