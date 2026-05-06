import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/bootstrap/auth_bootstrap_coordinator.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_binding.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  ref.read(authSessionBindingProvider);
  ref.read(socketSessionCoordinatorProvider);
  try {
    await ref.read(authBootstrapCoordinatorProvider).bootstrap();
  } catch (_) {}
  try {
    await ref.read(appLocaleControllerProvider.notifier).load();
  } catch (_) {}
  try {
    await ref.read(appThemeControllerProvider.notifier).load();
  } catch (_) {}
});
