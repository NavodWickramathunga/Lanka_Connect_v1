import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/screens/auth/auth_screen.dart';

void main() {
  testWidgets('auth entry screen renders and toggles signup mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Need an account? Sign up'), findsOneWidget);
    expect(find.text('Select role'), findsNothing);

    await tester.tap(find.text('Need an account? Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Select role'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
