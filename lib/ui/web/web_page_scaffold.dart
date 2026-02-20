import 'package:flutter/material.dart';
import 'web_tokens.dart';

class WebPageScaffold extends StatelessWidget {
  const WebPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.useScaffold = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool useScaffold;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(WebTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: WebTokens.spacingSm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: WebTypography.pageTitle(context)),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: WebTokens.spacingXs),
                    Text(subtitle!, style: WebTypography.pageSubtitle(context)),
                  ],
                ],
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: WebTokens.spacingSm, children: actions),
            ],
          ),
          const SizedBox(height: WebTokens.spacingMd),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WebTokens.surface,
                borderRadius: BorderRadius.circular(WebTokens.radiusLg),
                border: Border.all(color: WebTokens.border),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (!useScaffold) return content;

    return Scaffold(
      backgroundColor: WebTokens.background,
      body: SafeArea(child: content),
    );
  }
}
