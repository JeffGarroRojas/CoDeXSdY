import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codex_sdy/features/quiz/presentation/pages/quiz_home_page.dart';

void main() {
  group('QuizHomePage Widget Tests', () {
    Widget createTestWidget() {
      return ProviderScope(child: MaterialApp(home: const QuizHomePage()));
    }

    Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('should display app bar with title', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('Simulacros MEP'), findsOneWidget);
    });

    testWidgets('should display history button in app bar', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should display header card', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('Exámenes MEP Costa Rica'), findsOneWidget);
      expect(
        find.text('Prepárate para tus pruebas nacionales'),
        findsOneWidget,
      );
    });

    testWidgets('should display exam cards section', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('📝 Simulacros de Examen'), findsOneWidget);
    });

    testWidgets('should display three level exam cards', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('10° Año (1° Bachillerato)'), findsOneWidget);
      expect(find.text('11° Año (2° Bachillerato)'), findsOneWidget);
      expect(find.text('12° Año (3° Bachillerato)'), findsOneWidget);
    });

    testWidgets('should display quick practice section', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('🎯 Práctica Rápida'), findsOneWidget);
    });

    testWidgets('should display practice cards', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.text('Por Tema'), findsOneWidget);
      expect(find.text('Aleatorio'), findsOneWidget);
    });

    testWidgets('should display school icon in header', (tester) async {
      await pumpAndSettle(tester, createTestWidget());

      expect(find.byIcon(Icons.school), findsOneWidget);
    });
  });
}
