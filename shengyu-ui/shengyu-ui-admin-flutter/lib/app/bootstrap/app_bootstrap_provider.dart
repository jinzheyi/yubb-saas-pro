import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/bootstrap/auth_bootstrap_coordinator.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/shell/global_badge_socket_binding.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_binding.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/services/tenant_switch_service.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  // 使用 watch 而非 read，确保这些 provider 在应用全生命周期内保持活跃
  ref.watch(authSessionBindingProvider);
  ref.watch(socketSessionCoordinatorProvider);
  ref.watch(sessionCleanupServiceProvider);
  // 全局角标 Socket 绑定：必须在 bootstrap 级别 watch，
  // 因为 appBootstrapProvider 被 AppBootstrap (根 widget) watch，
  // 保证整个应用生命周期内始终监听 badge 推送，不受页面导航影响。
  ref.watch(globalBadgeSocketBindingProvider);

  // 先恢复登录态，再按该用户的 scope 预热 IM 缓存。此前与 auth 并行执行，
  // 很容易读取到匿名会话而跳过预热，导致每次冷启动仍进入骨架屏。
  await _safeBootstrap(
    ref,
    'auth',
    () => ref.read(authBootstrapCoordinatorProvider).bootstrap(),
  );

  // locale/theme 与 IM 缓存恢复没有依赖关系，可以并行。
  await Future.wait<void>([
    _safeBootstrap(
      ref,
      'locale',
      () => ref.read(appLocaleControllerProvider.notifier).load(),
    ),
    _safeBootstrap(
      ref,
      'theme',
      () => ref.read(appThemeControllerProvider.notifier).load(),
    ),
    _safeBootstrap(ref, 'im-cache', () => _warmImSession(ref)),
  ]);

  // 租户列表不影响会话首帧，在后台准备即可。
  unawaited(_safeBootstrap(ref, 'tenant-list', () => _preloadTenantList(ref)));
});

Future<void> _warmImSession(Ref ref) async {
  final session = ref.read(authSessionProvider);
  if (!session.isAuthenticated) {
    return;
  }
  await ref.read(conversationListControllerProvider.notifier).warmStart();
  // 复用既有缓存预热与性能统计；会话与最近消息已在 warmStart 中完成，
  // 此处命中 L1，不会重复读取磁盘。
  unawaited(_preloadImCache(ref));
}

/// Phase 5: 预加载 IM 缓存数据
///
/// 在用户登录后，异步预加载会话列表和前 5 个会话的消息到内存缓存，
/// 使得进入会话列表页和聊天页时可以直接从 L1 内存缓存读取，实现秒开。
Future<void> _preloadImCache(Ref ref) async {
  try {
    final session = ref.read(authSessionProvider);
    if (!session.isAuthenticated) {
      debugPrint('[Bootstrap] IM cache preload skipped: user not logged in');
      return;
    }

    final userId = session.userId;
    final cacheManager = ref.read(unifiedCacheManagerProvider);

    // 1. 从磁盘加载会话列表到内存（L2 → L1）
    final cached = await cacheManager.getConversationList(userId);
    if (cached != null) {
      debugPrint(
        '[Bootstrap] IM cache preloaded: ${cached.data.length} conversations',
      );

      // 2. 预加载前 5 个会话的消息到内存
      final recentChats = cached.data.take(5).toList();
      for (final conversation in recentChats) {
        await cacheManager.getMessages(userId, conversation.chatId);
      }
      debugPrint(
        '[Bootstrap] Preloaded messages for ${recentChats.length} recent chats',
      );

      // 3. 输出预加载后的缓存性能报告（用于调优）
      cacheManager.reportPerformance();
    }
  } catch (e, stack) {
    debugPrint('[Bootstrap] IM cache preload error: $e\n$stack');
  }
}

/// Phase 6: 预加载租户列表
///
/// 在用户登录后，异步预加载租户列表，使得打开租户切换面板时无需等待
Future<void> _preloadTenantList(Ref ref) async {
  try {
    final session = ref.read(authSessionProvider);
    if (!session.isAuthenticated) {
      debugPrint('[Bootstrap] Tenant list preload skipped: user not logged in');
      return;
    }

    final service = ref.read(tenantSwitchServiceProvider.notifier);
    await service.loadTenantList();
    final count = ref.read(tenantSwitchServiceProvider).tenantList.length;
    debugPrint('[Bootstrap] Tenant list preloaded: $count tenants');
  } catch (e, stack) {
    debugPrint('[Bootstrap] Tenant list preload error: $e\n$stack');
  }
}

Future<void> _safeBootstrap(
  Ref ref,
  String label,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (e, stack) {
    debugPrint('[Bootstrap] $label error: $e\n$stack');
  }
}
