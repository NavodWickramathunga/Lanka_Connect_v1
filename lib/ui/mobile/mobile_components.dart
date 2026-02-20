import 'package:flutter/material.dart';
import 'mobile_tokens.dart';

class MobileGradientHeader extends StatelessWidget {
  const MobileGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.accentColor,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MobileTokens.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MobileTokens.radiusLg),
        gradient: LinearGradient(
          colors: [accentColor, MobileTokens.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Color(0xFFE9F3FF)),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MobileSectionCard extends StatelessWidget {
  const MobileSectionCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(MobileTokens.spacingMd),
        child: child,
      ),
    );
  }
}

class MobileStatusChip extends StatelessWidget {
  const MobileStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class MobileEmptyState extends StatelessWidget {
  const MobileEmptyState({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: MobileTokens.inkMuted),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: MobileTokens.inkMuted)),
        ],
      ),
    );
  }
}
