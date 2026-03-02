import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class WebTokens {
  static const Color background = DesignTokens.background;
  static const Color backgroundDark = DesignTokens.backgroundDark;
  static const Color surface = DesignTokens.surface;
  static const Color surfaceMuted = DesignTokens.surfaceSoft;
  static const Color surfaceElevated = DesignTokens.surfaceElevated;
  static const Color inkPrimary = DesignTokens.textPrimary;
  static const Color inkSecondary = DesignTokens.textSecondary;
  static const Color inkSubtle = DesignTokens.textSubtle;
  static const Color brand = DesignTokens.brandPrimary;
  static const Color brandDark = Color(0xFF0F172A);
  static const Color brandAccent = DesignTokens.brandSecondary;
  static const Color border = DesignTokens.border;
  static const Color borderStrong = DesignTokens.borderStrong;
  static const Color success = DesignTokens.success;

  static const double spacing2xs = DesignTokens.space1;
  static const double spacingXs = DesignTokens.space2;
  static const double spacingSm = DesignTokens.space3;
  static const double spacingMd = DesignTokens.space4;
  static const double spacingMl = DesignTokens.space5;
  static const double spacingLg = DesignTokens.space6;
  static const double spacingXl = DesignTokens.space8;

  static const double radiusSm = DesignTokens.radiusSm;
  static const double radiusMd = DesignTokens.radiusMd;
  static const double radiusLg = DesignTokens.radiusLg;
  static const double radiusXl = DesignTokens.radiusXl;
}

class WebTypography {
  static TextStyle pageTitle(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle pageSubtitle(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: onSurface.withAlpha(153));
  }

  static TextStyle sectionTitle(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
    );
  }
}
