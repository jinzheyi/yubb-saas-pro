import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';

final authRefreshServiceProvider = Provider<AuthRefreshService>((ref) {
  return AuthRefreshService(ref, ref.read(authRemoteDataSourceProvider));
});

class AuthRefreshService {
  AuthRefreshService(this._ref, this._remoteDataSource);

  final Ref _ref;
  final AuthRemoteDataSource _remoteDataSource;

  Future<AuthSession> refreshCurrentSession() async {
    final current = _ref.read(authSessionProvider);
    if (current.refreshToken.isEmpty) {
      throw StateError('Missing refresh token');
    }

    final token = await _remoteDataSource.refreshToken(
      refreshToken: current.refreshToken,
      tenantId: current.tenantId,
    );
    if (!_isCurrentSession(current)) {
      return _ref.read(authSessionProvider);
    }
    final permissionInfo = await _remoteDataSource.getPermissionInfoWithSession(
      accessToken: token.accessToken,
      tenantId: token.tenantId,
    );
    if (!_isCurrentSession(current)) {
      return _ref.read(authSessionProvider);
    }
    final next = current.copyWith(
      userId: permissionInfo.userId,
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tenantId: token.tenantId,
    );
    await _ref.read(authSessionProvider.notifier).saveSession(next);
    return next;
  }

  bool _isCurrentSession(AuthSession snapshot) {
    final latest = _ref.read(authSessionProvider);
    return latest.userId == snapshot.userId &&
        latest.accessToken == snapshot.accessToken &&
        latest.refreshToken == snapshot.refreshToken &&
        latest.tenantId == snapshot.tenantId;
  }
}
