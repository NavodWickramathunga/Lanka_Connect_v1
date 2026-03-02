import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/screens/auth/auth_screen.dart';

void main() {
  testWidgets('auth entry screen renders and toggles signup mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    // Default state: login mode for Seeker portal
    expect(find.text('Seeker portal login'), findsOneWidget);
    expect(find.text('Login to Seeker Portal'), findsOneWidget);
    expect(find.text('Need an account? Sign up here'), findsOneWidget);
    expect(find.text('Create account as'), findsNothing);

    // Toggle to signup mode using the mode switch chip in the form header.
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your Lanka Connect account'), findsOneWidget);
    expect(find.text('Create account as'), findsOneWidget);
    expect(find.text('Create Seeker Account'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });
}
