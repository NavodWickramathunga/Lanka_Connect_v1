import 'package:flutter/material.dart';
import 'mobile_tokens.dart';

class MobileTheme {
  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: MobileTokens.primary,
      onPrimary: Colors.white,
      secondary: MobileTokens.secondary,
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: MobileTokens.surface,
      onSurface: MobileTokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MobileTokens.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: MobileTokens.ink,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: MobileTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          side: const BorderSide(color: MobileTokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: MobileTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: MobileTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: MobileTokens.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MobileTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MobileTokens.primary,
          side: const BorderSide(color: MobileTokens.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: MobileTokens.primary,
        unselectedItemColor: MobileTokens.inkMuted,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  static ThemeData buildDark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF66B2FF),
      onPrimary: Color(0xFF03233D),
      secondary: Color(0xFF3BD7BE),
      onSecondary: Color(0xFF002A24),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF121C27),
      onSurface: Color(0xFFE6EEF8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0C141E),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE6EEF8),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF152131),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          side: const BorderSide(color: Color(0xFF28384D)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF152131),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF2A3C52)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF2A3C52)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF66B2FF), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66B2FF),
          foregroundColor: const Color(0xFF03233D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9BCBFF),
          side: const BorderSide(color: Color(0xFF66B2FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF66B2FF),
        unselectedItemColor: Color(0xFF9BB1C7),
        backgroundColor: Color(0xFF121C27),
        elevation: 6,
      ),
    );
  }
}
