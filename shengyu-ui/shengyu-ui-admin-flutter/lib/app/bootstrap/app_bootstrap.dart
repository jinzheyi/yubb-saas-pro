import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/shell/global_badge_socket_binding.dart';
import 'package:shengyu_ui_admin_im/app/splash/app_splash_screen.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

import 'app_bootstrap_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(appBootstrapProvider);
    // 全局角标 Socket 绑定：在根 widget 级别 watch，
    // 确保整个应用生命周期内始终监听 badge 推送，不受 FutureProvider 完成状态影响。
    ref.watch(globalBadgeSocketBindingProvider);
    // 全局通话控制器绑定：在根 widget 级别 watch，
    // 确保应用启动时就初始化 CallController，激活 WebSocket 来电监听，
    // 避免丢失来电邀请事件。
    ref.watch(callControllerProvider);
    final locale = ref.watch(appLocaleObjectProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final router = ref.watch(appRouterProvider);

    final app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );

    // ===== P5-1: 启动期间展示 Splash Screen =====
    return bootstrapState.when(
      data: (_) => app,
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AppSplashScreen(),
      ),
      error: (_, __) => app,
    );
  }
}
