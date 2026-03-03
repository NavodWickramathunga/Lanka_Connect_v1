import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/screens/services/widgets/service_editor_form.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('create mode renders Post Service submit label', (tester) async {
    await tester.pumpWidget(
      wrap(const ServiceEditorForm(enableImagePicking: false)),
    );

    expect(find.byKey(const Key('service_editor_submit')), findsOneWidget);
    expect(find.text('Post Service'), findsOneWidget);
  });

  testWidgets('edit mode renders Update Service submit label', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ServiceEditorForm(
          serviceId: 'svc_1',
          initialData: <String, dynamic>{},
          enableImagePicking: false,
        ),
      ),
    );

    expect(find.byKey(const Key('service_editor_submit')), findsOneWidget);
    expect(find.text('Update Service'), findsOneWidget);
  });

  testWidgets('empty submit shows required field validation messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const ServiceEditorForm(enableImagePicking: false)),
    );

    await tester.ensureVisible(find.byKey(const Key('service_editor_submit')));
    await tester.tap(find.byKey(const Key('service_editor_submit')));
    await tester.pump();

    expect(find.text('Title required'), findsOneWidget);
    expect(find.text('Category required'), findsOneWidget);
    expect(find.text('Price required'), findsOneWidget);
    expect(find.text('District required'), findsOneWidget);
    expect(find.text('City required'), findsOneWidget);
    expect(find.text('Description required'), findsOneWidget);
  });
}
