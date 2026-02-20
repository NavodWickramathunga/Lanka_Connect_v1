import 'package:flutter/material.dart';

class WebTokens {
  static const Color background = Color(0xFFF2F7FF);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF7FBFF);
  static const Color inkPrimary = Color(0xFF0F2F45);
  static const Color inkSecondary = Color(0xFF406074);
  static const Color brand = Color(0xFF1769AA);
  static const Color brandDark = Color(0xFF103B56);
  static const Color border = Color(0xFFD5E3EE);
  static const Color success = Color(0xFF1F8C5F);

  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static const double radiusMd = 12;
  static const double radiusLg = 18;
}

class WebTypography {
  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: WebTokens.inkPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle pageSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: WebTokens.inkSecondary,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: WebTokens.inkPrimary,
      fontWeight: FontWeight.w600,
    );
  }
}
