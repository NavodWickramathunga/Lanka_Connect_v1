import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
import 'widgets/service_editor_form.dart';

class ServiceFormScreen extends StatelessWidget {
  const ServiceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = ServiceEditorForm(
      onSaved: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );

    if (kIsWeb) {
      return WebPageScaffold(
        title: 'Post Service',
        subtitle: 'Create a new service listing for seekers to discover.',
        useScaffold: true,
        child: body,
      );
    }

    return MobilePageScaffold(
      title: 'Post Service',
      subtitle: 'Create a new service listing for seekers to discover.',
      accentColor: MobileTokens.primary,
      useScaffold: true,
      body: body,
    );
  }
}
