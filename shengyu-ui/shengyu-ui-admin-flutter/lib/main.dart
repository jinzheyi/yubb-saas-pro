import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/bootstrap/app_bootstrap.dart';
import 'package:shengyu_ui_admin_im/core/debug/provider_scope_checker.dart';
import 'package:shengyu_ui_admin_im/core/lifecycle/app_lifecycle_manager.dart';
import 'package:shengyu_ui_admin_im/core/network/network_monitor_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';

void main() async {
  // 初始化 Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 App 生命周期管理
  AppLifecycleManager().init();

  // 初始化网络监控
  NetworkMonitorService().init();

  // 构建 observers 列表
  final observers = <ProviderObserver>[_LifecycleBindingObserver()];
  
  // 仅在 debug 模式下添加 Provider 作用域检查工具
  if (kDebugMode) {
    observers.add(ProviderScopeChecker());
  }

  runApp(ProviderScope(
    observers: observers,
    child: const ShengyuImApp(),
  ));
}

/// 将 SocketSessionCoordinator 注入到 AppLifecycleManager
class _LifecycleBindingObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == socketSessionCoordinatorProvider && newValue != null) {
      AppLifecycleManager().setSocketCoordinator(newValue as SocketSessionCoordinator);
    }
  }
}

class ShengyuImApp extends ConsumerStatefulWidget {
  const ShengyuImApp({super.key});

  @override
  ConsumerState<ShengyuImApp> createState() => _ShengyuImAppState();
}

class _ShengyuImAppState extends ConsumerState<ShengyuImApp> {
  @override
  void initState() {
    super.initState();
    // 在 initState 中配置图片缓存，确保 binding 已完全初始化
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
  }

  @override
  Widget build(BuildContext context) {
    return const AppBootstrap();
  }
}
