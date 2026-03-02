import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../../utils/user_roles.dart';

class MobileTokens {
  static const Color primary = DesignTokens.brandPrimary;
  static const Color secondary = DesignTokens.brandSecondary;
  static const Color accent = DesignTokens.accent;
  static const Color brandInk = DesignTokens.brandInk;
  static const Color surface = DesignTokens.surface;
  static const Color surfaceSoft = DesignTokens.surfaceSoft;
  static const Color surfaceElevated = DesignTokens.surfaceElevated;
  static const Color background = DesignTokens.background;
  static const Color backgroundDark = DesignTokens.backgroundDark;
  static const Color ink = DesignTokens.textPrimary;
  static const Color inkMuted = DesignTokens.textSecondary;
  static const Color inkSubtle = DesignTokens.textSubtle;
  static const Color border = DesignTokens.border;
  static const Color borderStrong = DesignTokens.borderStrong;

  static const double radiusSm = DesignTokens.radiusSm;
  static const double radiusMd = DesignTokens.radiusMd;
  static const double radiusLg = DesignTokens.radiusLg;
  static const double radiusXl = DesignTokens.radiusXl;
  static const double radius2xl = DesignTokens.radius2xl;
  static const double spacing2xs = DesignTokens.space1;
  static const double spacingXs = DesignTokens.space2;
  static const double spacingSm = DesignTokens.space3;
  static const double spacingMd = DesignTokens.space4;
  static const double spacingMl = DesignTokens.space5;
  static const double spacingLg = DesignTokens.space6;
  static const double spacingXl = DesignTokens.space8;
}

class RoleVisuals {
  const RoleVisuals({
    required this.accent,
    required this.icon,
    required this.chipBackground,
  });

  final Color accent;
  final IconData icon;
  final Color chipBackground;

  static RoleVisuals forRole(String role) {
    if (role == UserRoles.provider) {
      return const RoleVisuals(
        accent: Color(0xFF0EA5A4),
        icon: Icons.engineering,
        chipBackground: Color(0xFFCCFBF1),
      );
    }
    if (role == UserRoles.admin) {
      return const RoleVisuals(
        accent: Color(0xFFEA580C),
        icon: Icons.admin_panel_settings,
        chipBackground: Color(0xFFFFEDD5),
      );
    }
    return const RoleVisuals(
      accent: Color(0xFF0284C7),
      icon: Icons.search,
      chipBackground: Color(0xFFE0F2FE),
    );
  }
}
