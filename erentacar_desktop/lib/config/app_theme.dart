import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1F2A44);
  static const Color accent = Color(0xFF2E75B6);
  static const Color success = Color(0xFF2FAE66);
  static const Color error = Color(0xFFE0483B);
  static const Color background = Color(0xFFF4F6FA);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF27314A);
  static const Color textMuted = Color(0xFF8A93A6);

  static ThemeData get theme => ThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: error),
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}