import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';

final authBootstrapCoordinatorProvider = Provider<AuthBootstrapCoordinator>((
  ref,
) {
  return AuthBootstrapCoordinator(ref);
});

class AuthBootstrapCoordinator {
  AuthBootstrapCoordinator(this._ref);

  final Ref _ref;

  Future<void> bootstrap() async {
    await _ref.read(authSessionProvider.notifier).restore();
    _ref.read(dioProvider);
  }
}
