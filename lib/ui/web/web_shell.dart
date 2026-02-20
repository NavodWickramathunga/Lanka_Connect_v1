import 'package:flutter/material.dart';
import 'web_tokens.dart';

class WebShellNavItem {
  const WebShellNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class WebShell extends StatelessWidget {
  const WebShell({
    super.key,
    required this.appTitle,
    required this.navItems,
    required this.currentId,
    required this.onSelect,
    required this.pageTitle,
    this.pageSubtitle,
    this.actions = const [],
    required this.child,
  });

  final String appTitle;
  final List<WebShellNavItem> navItems;
  final String currentId;
  final ValueChanged<String> onSelect;
  final String pageTitle;
  final String? pageSubtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTokens.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            return Row(
              children: [
                _Sidebar(
                  appTitle: appTitle,
                  compact: compact,
                  items: navItems,
                  currentId: currentId,
                  onSelect: onSelect,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 76,
                        margin: const EdgeInsets.all(WebTokens.spacingMd),
                        padding: const EdgeInsets.symmetric(
                          horizontal: WebTokens.spacingLg,
                        ),
                        decoration: BoxDecoration(
                          color: WebTokens.surface,
                          borderRadius: BorderRadius.circular(
                            WebTokens.radiusLg,
                          ),
                          border: Border.all(color: WebTokens.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    pageTitle,
                                    style: WebTypography.sectionTitle(context),
                                  ),
                                  if (pageSubtitle != null)
                                    Text(
                                      pageSubtitle!,
                                      style: WebTypography.pageSubtitle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: WebTokens.spacingSm,
                              children: actions,
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.appTitle,
    required this.compact,
    required this.items,
    required this.currentId,
    required this.onSelect,
  });

  final String appTitle;
  final bool compact;
  final List<WebShellNavItem> items;
  final String currentId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 86 : 250,
      margin: const EdgeInsets.fromLTRB(
        WebTokens.spacingMd,
        WebTokens.spacingMd,
        0,
        WebTokens.spacingMd,
      ),
      padding: const EdgeInsets.all(WebTokens.spacingMd),
      decoration: BoxDecoration(
        color: WebTokens.brandDark,
        borderRadius: BorderRadius.circular(WebTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Icon(Icons.public, color: Colors.white, size: compact ? 26 : 24),
          if (!compact) ...[
            const SizedBox(height: WebTokens.spacingSm),
            Text(
              appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: WebTokens.spacingLg),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: WebTokens.spacingXs),
              child: _SidebarItem(
                item: item,
                compact: compact,
                selected: item.id == currentId,
                onTap: () => onSelect(item.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final WebShellNavItem item;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTokens.radiusMd),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? WebTokens.spacingXs : WebTokens.spacingSm,
          vertical: WebTokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A5E84) : Colors.transparent,
          borderRadius: BorderRadius.circular(WebTokens.radiusMd),
          border: selected
              ? Border.all(color: const Color(0xFF7CC0E6))
              : Border.all(color: Colors.transparent),
        ),
        child: compact
            ? Icon(item.icon, color: Colors.white)
            : Row(
                children: [
                  Icon(item.icon, color: Colors.white),
                  const SizedBox(width: WebTokens.spacingSm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
