import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    fontFamily: 'AppSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF246BFD),
      brightness: Brightness.light,
      surface: Colors.white,
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
  );

  static ThemeData get dark => ThemeData(
    fontFamily: 'AppSans',
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF246BFD),
    ),
    useMaterial3: true,
  );
}
