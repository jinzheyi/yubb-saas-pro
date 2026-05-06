import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

enum AppLanguageMode { system, zhCn, en }

class AppLocaleState {
  const AppLocaleState({
    required this.languageMode,
    required this.resolvedLocale,
  });

  final AppLanguageMode languageMode;
  final Locale resolvedLocale;

  bool get isFollowingSystem => languageMode == AppLanguageMode.system;
  String get resolvedTag =>
      resolvedLocale.countryCode == null || resolvedLocale.countryCode!.isEmpty
      ? resolvedLocale.languageCode
      : '${resolvedLocale.languageCode}-${resolvedLocale.countryCode}';

  AppLocaleState copyWith({
    AppLanguageMode? languageMode,
    Locale? resolvedLocale,
  }) {
    return AppLocaleState(
      languageMode: languageMode ?? this.languageMode,
      resolvedLocale: resolvedLocale ?? this.resolvedLocale,
    );
  }
}

final appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, AppLocaleState>((ref) {
      return AppLocaleController(ref);
    });

final appLocaleProvider = Provider<String>((ref) {
  return ref.watch(appLocaleControllerProvider).resolvedTag;
});

final appLocaleObjectProvider = Provider<Locale>((ref) {
  return ref.watch(appLocaleControllerProvider).resolvedLocale;
});

class AppLocaleController extends StateNotifier<AppLocaleState> {
  AppLocaleController(this._ref)
    : super(
        AppLocaleState(
          languageMode: AppLanguageMode.system,
          resolvedLocale: _resolveLocale(AppLanguageMode.system),
        ),
      );

  final Ref _ref;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeyRegistry.languageMode);
    final mode = _parseMode(raw);
    final locale = _resolveLocale(mode);
    state = state.copyWith(languageMode: mode, resolvedLocale: locale);
    await _ref
        .read(authSessionProvider.notifier)
        .updateLocale(_toLocaleTag(locale));
  }

  Future<void> selectLanguageMode(AppLanguageMode mode) async {
    final locale = _resolveLocale(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeyRegistry.languageMode, mode.name);
    state = state.copyWith(languageMode: mode, resolvedLocale: locale);
    await _ref
        .read(authSessionProvider.notifier)
        .updateLocale(_toLocaleTag(locale));
  }

  static AppLanguageMode _parseMode(String? raw) {
    return switch (raw) {
      'zhCn' => AppLanguageMode.zhCn,
      'en' => AppLanguageMode.en,
      _ => AppLanguageMode.system,
    };
  }

  static Locale _resolveLocale(AppLanguageMode mode) {
    return switch (mode) {
      AppLanguageMode.system => _sanitizeLocale(
        WidgetsBinding.instance.platformDispatcher.locale,
      ),
      AppLanguageMode.zhCn => const Locale('zh', 'CN'),
      AppLanguageMode.en => const Locale('en'),
    };
  }

  static Locale _sanitizeLocale(Locale locale) {
    final languageCode = locale.languageCode.isEmpty
        ? 'zh'
        : locale.languageCode;
    final countryCode =
        locale.countryCode == null || locale.countryCode!.isEmpty
        ? (languageCode == 'zh' ? 'CN' : null)
        : locale.countryCode;
    return Locale(languageCode, countryCode);
  }

  static String _toLocaleTag(Locale locale) {
    return locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
  }
}
