import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/features/auth/presentation/pages/auth_page.dart';

void main() {
  group('AuthPage Widget Tests', () {
    testWidgets('should display logo and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPage(onLoginSuccess: () {}, onGuestMode: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CoDeXSdY'), findsOneWidget);
    });

    testWidgets('should show login form by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPage(onLoginSuccess: () {}, onGuestMode: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('should have Google sign in button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPage(onLoginSuccess: () {}, onGuestMode: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('should have email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPage(onLoginSuccess: () {}, onGuestMode: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeast(2));
    });
  });
}
