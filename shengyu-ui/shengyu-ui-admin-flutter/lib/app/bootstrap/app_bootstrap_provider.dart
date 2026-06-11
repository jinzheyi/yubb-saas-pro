import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/bootstrap/auth_bootstrap_coordinator.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/shell/global_badge_socket_binding.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_binding.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  // 使用 watch 而非 read，确保这些 provider 在应用全生命周期内保持活跃
  ref.watch(authSessionBindingProvider);
  ref.watch(socketSessionCoordinatorProvider);
  ref.watch(sessionCleanupServiceProvider);
  // 全局角标 Socket 绑定：必须在 bootstrap 级别 watch，
  // 因为 appBootstrapProvider 被 AppBootstrap (根 widget) watch，
  // 保证整个应用生命周期内始终监听 badge 推送，不受页面导航影响。
  ref.watch(globalBadgeSocketBindingProvider);
  try {
    await ref.read(authBootstrapCoordinatorProvider).bootstrap();
  } catch (e, stack) {
    debugPrint('[Bootstrap] auth bootstrap error: $e\n$stack');
  }
  try {
    await ref.read(appLocaleControllerProvider.notifier).load();
  } catch (e, stack) {
    debugPrint('[Bootstrap] locale load error: $e\n$stack');
  }
  try {
    await ref.read(appThemeControllerProvider.notifier).load();
  } catch (e, stack) {
    debugPrint('[Bootstrap] theme load error: $e\n$stack');
  }
});
