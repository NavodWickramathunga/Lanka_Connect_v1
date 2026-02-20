import 'package:flutter/material.dart';
import '../../utils/user_roles.dart';

class MobileTokens {
  static const Color primary = Color(0xFF0F6CBD);
  static const Color secondary = Color(0xFF00A58E);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F8FF);
  static const Color background = Color(0xFFEEF5FF);
  static const Color ink = Color(0xFF123047);
  static const Color inkMuted = Color(0xFF5B748A);
  static const Color border = Color(0xFFD5E3F1);

  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
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
        accent: Color(0xFF0EA37A),
        icon: Icons.engineering,
        chipBackground: Color(0xFFE3FAF3),
      );
    }
    if (role == UserRoles.admin) {
      return const RoleVisuals(
        accent: Color(0xFFB0542B),
        icon: Icons.admin_panel_settings,
        chipBackground: Color(0xFFFFEFE4),
      );
    }
    return const RoleVisuals(
      accent: Color(0xFF2667CF),
      icon: Icons.search,
      chipBackground: Color(0xFFEAF0FF),
    );
  }
}
