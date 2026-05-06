import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

class AppThemeState {
  const AppThemeState({required this.themeMode});

  final ThemeMode themeMode;

  bool get isFollowingSystem => themeMode == ThemeMode.system;

  AppThemeState copyWith({ThemeMode? themeMode}) {
    return AppThemeState(themeMode: themeMode ?? this.themeMode);
  }
}

final appThemeControllerProvider =
    StateNotifierProvider<AppThemeController, AppThemeState>((ref) {
      return AppThemeController();
    });

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appThemeControllerProvider).themeMode;
});

class AppThemeController extends StateNotifier<AppThemeState> {
  AppThemeController()
    : super(const AppThemeState(themeMode: ThemeMode.system));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeyRegistry.themeMode);
    state = state.copyWith(themeMode: _parseMode(raw));
  }

  Future<void> selectThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeyRegistry.themeMode, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  static ThemeMode _parseMode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
