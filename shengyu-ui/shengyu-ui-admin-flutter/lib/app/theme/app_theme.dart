import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    fontFamily: 'AppSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF246BFD),
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF202531),
      onSurfaceVariant: const Color(0xFF8F96A3),
      primaryContainer: const Color(0xFFEAF2FF),
      onPrimaryContainer: const Color(0xFF246BFD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    dividerColor: const Color(0xFFE9EDF3),
    useMaterial3: false,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Color(0xFF202531)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF202531),
      ),
    ),
    cardColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF246BFD), width: 1.2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8F96A3),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF202531),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    fontFamily: 'AppSans',
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF246BFD),
      surface: const Color(0xFF1E2430),
      onSurface: const Color(0xFFE8EAED),
      onSurfaceVariant: const Color(0xFF8F96A3),
      primaryContainer: const Color(0xFF1A3A6B),
      onPrimaryContainer: const Color(0xFF6BA4FF),
    ),
    scaffoldBackgroundColor: const Color(0xFF121620),
    dividerColor: const Color(0xFF2A3140),
    useMaterial3: false,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E2430),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Color(0xFFE8EAED)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFFE8EAED),
      ),
    ),
    cardColor: const Color(0xFF1E2430),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A3140),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF246BFD), width: 1.2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8F96A3),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E2430),
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFFE8EAED),
      ),
    ),
  );
}
