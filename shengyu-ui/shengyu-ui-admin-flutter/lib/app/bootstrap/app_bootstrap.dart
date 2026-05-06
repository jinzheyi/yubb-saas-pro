import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_mode_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

import 'app_bootstrap_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBootstrapProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleObjectProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
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
  }
}
