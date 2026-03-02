import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'mobile_tokens.dart';

class MobileTheme {
  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: MobileTokens.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: MobileTokens.primary,
      onPrimary: Colors.white,
      secondary: MobileTokens.secondary,
      onSecondary: MobileTokens.brandInk,
      error: DesignTokens.danger,
      onError: Colors.white,
      surface: MobileTokens.surface,
      onSurface: MobileTokens.ink,
      outline: MobileTokens.border,
      outlineVariant: MobileTokens.borderStrong,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MobileTokens.background,
      textTheme: const TextTheme(
        displaySmall: AppTypeScale.display,
        headlineMedium: AppTypeScale.headline,
        titleLarge: AppTypeScale.title,
        titleMedium: AppTypeScale.subtitle,
        bodyMedium: AppTypeScale.body,
        bodySmall: AppTypeScale.label,
      ),
      appBarTheme: AppBarTheme(
        elevation: DesignTokens.elevation0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: MobileTokens.ink,
        scrolledUnderElevation: DesignTokens.elevation0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MobileTokens.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: DesignTokens.elevation1,
        color: MobileTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusLg),
          side: const BorderSide(color: MobileTokens.border),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusSm),
          side: const BorderSide(color: MobileTokens.border),
        ),
        backgroundColor: MobileTokens.surfaceSoft,
        side: const BorderSide(color: MobileTokens.border),
        selectedColor: MobileTokens.primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(
          color: MobileTokens.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: MobileTokens.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MobileTokens.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: MobileTokens.inkMuted,
          fontWeight: FontWeight.w500,
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
          elevation: DesignTokens.elevation1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MobileTokens.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFCCFBF1),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    final scheme = ColorScheme.fromSeed(
      seedColor: MobileTokens.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF2DD4BF),
      onPrimary: const Color(0xFF062421),
      secondary: const Color(0xFFF59E0B),
      onSecondary: const Color(0xFF261700),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      surface: const Color(0xFF0F172A),
      onSurface: const Color(0xFFE2E8F0),
      outline: const Color(0xFF334155),
      outlineVariant: const Color(0xFF475569),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MobileTokens.backgroundDark,
      textTheme: const TextTheme(
        displaySmall: AppTypeScale.display,
        headlineMedium: AppTypeScale.headline,
        titleLarge: AppTypeScale.title,
        titleMedium: AppTypeScale.subtitle,
        bodyMedium: AppTypeScale.body,
        bodySmall: AppTypeScale.label,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE2E8F0),
        scrolledUnderElevation: DesignTokens.elevation0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF111C31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusLg),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusSm),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        backgroundColor: const Color(0xFF111827),
        side: const BorderSide(color: Color(0xFF334155)),
        selectedColor: const Color(0xFF134E4A),
        labelStyle: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF5EEAD4),
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: const Color(0xFF062421),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5EEAD4),
          side: const BorderSide(color: Color(0xFF2DD4BF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5EEAD4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        indicatorColor: Color(0xFF134E4A),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF5EEAD4),
        unselectedItemColor: Color(0xFF94A3B8),
        backgroundColor: Color(0xFF0F172A),
        elevation: 6,
      ),
    );
  }
}
