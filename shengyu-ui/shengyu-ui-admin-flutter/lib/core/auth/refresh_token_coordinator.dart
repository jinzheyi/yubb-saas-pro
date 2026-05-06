import 'dart:async';

import 'auth_session.dart';

typedef RefreshSessionTask = Future<AuthSession> Function();

class RefreshTokenCoordinator {
  Future<AuthSession>? _inflightRefresh;

  Future<AuthSession> refresh(RefreshSessionTask task) {
    final inflightRefresh = _inflightRefresh;
    if (inflightRefresh != null) {
      return inflightRefresh;
    }

    final future = task();
    _inflightRefresh = future;
    return future.whenComplete(() {
      _inflightRefresh = null;
    });
  }
}
