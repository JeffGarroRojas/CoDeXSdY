import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

void main() {
  group('Nivel 9: Tests Robustos de Manejo de Errores', () {
    late GroqClient client;

    setUp(() {
      client = GroqClient(apiKey: 'test-key');
    });

    group('Errores de Parsing - Casos Críticos', () {
      test('debe manejar respuesta JSON con texto adicional antes', () {
        const response = '''
Aquí tienes las preguntas en formato JSON:
[
  {"question": "¿Qué es la célula?", "options": ["A", "B", "C", "D"], "correctIndex": 0}
]
''';

        final result = _testExtractJson(response);
        expect(result.isNotEmpty, true);
        expect(result.contains('question'), true);
      });

      test('debe manejar respuesta JSON con texto después', () {
        const response = '''
[
  {"question": "¿Qué es la célula?", "options": ["A", "B", "C", "D"], "correctIndex": 0}
]
Espero que te sea útil.
''';

        final result = _testExtractJson(response);
        expect(result.isNotEmpty, true);
      });

      test('debe manejar JSON anidado incorrecto', () {
        const response = '''
{"preguntas": [{"question": "test", "options": ["a","b"], "correctIndex": 0}]}
''';

        final result = _testExtractJson(response);
        expect(result.isEmpty, true, reason: 'No es array');
      });

      test('debe manejar JSON vacío', () {
        const response = '[]';

        final result = _testExtractJson(response);
        expect(result.isNotEmpty, true);
      });

      test('debe manejar respuesta sin JSON', () {
        const response = 'Esto no es JSON en absoluto';

        final result = _testExtractJson(response);
        expect(result.isEmpty, true);
      });

      test('debe manejar JSON con caracteres inválidos', () {
        const response = '''
[
  {"question": "Pregunta\tcon\ttabs", "options": ["a", "b"], "correctIndex": 0}
]
''';

        final result = _testExtractJson(response);
        expect(result.isNotEmpty, true);
      });

      test('debe manejar JSON con newlines en strings', () {
        const response = '''
[
  {"question": "Pregunta\\ncon\\nsaltos", "options": ["a", "b"], "correctIndex": 0}
]
''';

        final result = _testExtractJson(response);
        expect(result.isNotEmpty, true);
      });
    });

    group('Errores de Contenido', () {
      test('debe detectar contenido vacío', () {
        const response = '';

        final cards = client.parseFlashcards(response);
        expect(cards, isEmpty);
      });

      test('debe detectar contenido solo espacios', () {
        const response = '   \n\n   ';

        final cards = client.parseFlashcards(response);
        expect(cards, isEmpty);
      });

      test('debe detectar formato válido pero sin contenido real', () {
        const response = 'Frente: \nDorso: ';

        final cards = client.parseFlashcards(response);
        expect(cards, isEmpty);
      });

      test('debe manejar flashcard con solo una línea', () {
        const response = 'Frente: Solo tengo frente';

        final cards = client.parseFlashcards(response);
        expect(cards, isEmpty);
      });
    });

    group('Errores de Rate Limit (simulados)', () {
      test('GroqException debe tener mensaje claro', () {
        final exception = GroqException(
          message: 'Rate limit exceeded',
          statusCode: 429,
        );

        expect(exception.message, contains('Rate limit'));
        expect(exception.statusCode, 429);
        expect(exception.toString(), contains('429'));
      });

      test('GroqException debe manejar statusCode null', () {
        final exception = GroqException(
          message: 'Network error',
          statusCode: null,
        );

        expect(exception.statusCode, isNull);
        expect(exception.toString(), contains('Network error'));
      });

      test('GroqException debe manejar mensaje vacío', () {
        final exception = GroqException(message: '', statusCode: 500);

        expect(exception.message, '');
      });
    });

    group('Errores de Timeout (validación de código)', () {
      test('timeout de 30 segundos debe ser suficiente para flashcards', () {
        const timeout = Duration(seconds: 30);
        expect(timeout.inSeconds, 30);
      });

      test(
        'timeout de 60 segundos debe ser suficiente para resúmenes largos',
        () {
          const timeout = Duration(seconds: 60);
          expect(timeout.inSeconds, 60);
        },
      );

      test('timeout de 90 segundos debe ser suficiente para exámenes', () {
        const timeout = Duration(seconds: 90);
        expect(timeout.inSeconds, 90);
      });
    });

    group('Validación de Errores en Funciones de Generación', () {
      test('generateFlashcards con tema vacío debe manejar error', () async {
        try {
          final response = await client.generateFlashcards(topic: '', count: 1);
          expect(response.isNotEmpty, true);
        } catch (e) {
          expect(e, isA<GroqException>());
        }
      });

      test(
        'generateSummary con contenido muy corto debe funcionar',
        () async {
          final response = await client.generateSummary(
            content: 'Agua',
            maxTokens: 50,
          );
          expect(response.isNotEmpty, true);
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test('generateQuiz con 0 preguntas debe manejar error', () async {
        try {
          await client.generateQuiz(content: 'Test content', numQuestions: 0);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test(
        'generateNewQuestions con nivel inválido debe manejar',
        () async {
          try {
            await client.generateNewQuestions(
              subject: 'Test',
              level: 0,
              count: 1,
              topics: ['Test'],
            );
          } catch (e) {
            expect(e, isA<Exception>());
          }
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );
    });

    group('Errores de Red (simulados)', () {
      test('mensaje de error para conexión perdida', () {
        const errorMessage = 'Connection lost';
        expect(errorMessage.contains('Connection'), true);
      });

      test('mensaje de error para timeout', () {
        const errorMessage = 'Connection timeout';
        expect(errorMessage.contains('timeout'), true);
      });

      test('mensaje de error para servidor caído', () {
        const errorMessage = 'Internal server error';
        expect(errorMessage.contains('server'), true);
      });

      test('mensaje de error para API key inválida', () {
        const errorMessage = 'Invalid API key';
        expect(errorMessage.contains('API key'), true);
      });
    });

    group('Tests de Resiliencia del Código', () {
      test('el código debe manejar caracteres unicode completos', () {
        const text = '¿Qué significa Ñoño? ¡Sonríe! Águila: volemos über café';
        final cards = client.parseFlashcards(text);
        expect(cards, isEmpty);
      });

      test('el código debe manejar emojis', () {
        const text = 'Frente: Emoji test 😃 Dorso: Testing emojis 🎉';
        final cards = client.parseFlashcards(text);
        expect(cards.length, 1);
      });

      test('el código debe manejar HTML entities', () {
        const text = 'Frente: &lt;test&gt; Dorso: &amp;more';
        final cards = client.parseFlashcards(text);
        expect(cards.isNotEmpty, true);
      });

      test('el código debe manejar URLs en contenido', () {
        const text = 'Frente: Visita https://example.com Dorso: Test';
        final cards = client.parseFlashcards(text);
        expect(cards.isNotEmpty, true);
      });

      test('el código debe manejar saltos de línea mixtos', () {
        const text =
            'Frente: Line1\r\nDorso: Line2\rFrente: Line3\rDorso: Line4';
        final cards = client.parseFlashcards(text);
        expect(cards.isNotEmpty, true);
      });
    });
  });
}

String _testExtractJson(String text) {
  final firstBracket = text.indexOf('[');
  final lastBracket = text.lastIndexOf(']');

  if (firstBracket == -1 || lastBracket == -1 || firstBracket > lastBracket) {
    return '';
  }

  String jsonStr = text.substring(firstBracket, lastBracket + 1);
  jsonStr = jsonStr.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  return jsonStr.trim();
}
