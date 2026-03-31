import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

void main() {
  group('Nivel 5-7: Tests Robustos de Flashcards y Parsing', () {
    late GroqClient client;

    setUp(() {
      client = GroqClient(apiKey: 'test-key');
    });

    group('Parsing de Flashcards - Casos Reales', () {
      test('debe parsear formato estándar Frente:/Dorso:', () {
        const response = '''
Frente: ¿Qué es la fotosíntesis?
Dorso: Proceso por el cual las plantas convierten luz en energía

Frente: ¿Quién descubrió América?
Dorso: Cristóbal Colón en 1492

Frente: ¿Capital de Francia?
Dorso: París
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 3);
        expect(cards[0]['front'], contains('fotosíntesis'));
        expect(cards[0]['back'], contains('plantas'));
        expect(cards[1]['front'], contains('América'));
        expect(cards[2]['front'], contains('Francia'));
      });

      test('debe parsear formato Pregunta:/Respuesta:', () {
        const response = '''
Pregunta: ¿Qué es la mitosis?
Respuesta: División celular que produce células hija idénticas

Pregunta: ¿Qué es la meiosis?
Respuesta: División celular que produce células haploides
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 2);
        expect(cards[0]['front'], contains('mitosis'));
        expect(cards[1]['front'], contains('meiosis'));
      });

      test('debe manejar texto adicional antes del contenido', () {
        const response = '''
Aquí tienes las flashcards que solicitaste:

Frente: ¿Qué es el ADN?
Dorso: Ácido desoxirribonucleico

Frente: ¿Qué es el ARN?
Dorso: Ácido ribonucleico
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 2);
        expect(cards[0]['front'], contains('ADN'));
      });

      test('debe manejar texto después del contenido', () {
        const response = '''
Frente: ¿Qué es la gravedad?
Dorso: Fuerza de atracción entre cuerpos

Frente: ¿Qué es la inercia?
Dorso: Resistencia de los cuerpos a cambiar su estado

Espero que estas tarjetas te ayuden con tus estudios.
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 2);
      });

      test('debe manejar múltiples flashcards en una línea', () {
        const response =
            'Frente: Pregunta 1 Dorso: Respuesta 1 Frente: Pregunta 2 Dorso: Respuesta 2';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 2);
      });

      test('debe manejar flashcard incompleta (solo frente)', () {
        const response = '''
Frente: ¿Solo tengo frente?

Esto no debería ser una flashcard.
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 0);
      });

      test('debe manejar respuesta vacía', () {
        const response = '';

        final cards = client.parseFlashcards(response);

        expect(cards, isEmpty);
      });

      test('debe manejar formato con números', () {
        const response = '''
1. ¿Qué es la célula?
   Respuesta: Unidad básica de la vida

2. ¿Qué es el núcleo?
   Respuesta: Centro de control de la célula
''';

        final cards = client.parseFlashcards(response);

        expect(cards.isNotEmpty, true);
      });

      test('debe manejar tildes y caracteres especiales', () {
        const response = '''
Frente: ¿Qué función tiene el corazón?
Dorso: Bombear sangre por todo el cuerpo

Frente: ¿Qué significa Noël?
Dorso: Navidad en francés
''';

        final cards = client.parseFlashcards(response);

        expect(cards.length, 2);
        expect(cards[0]['back'], contains('cuerpo'));
      });
    });

    group('Generación de Flashcards - Tests de API', () {
      test(
        'Nivel 5a: Generar flashcards tema simple',
        () async {
          final response = await client.generateFlashcards(
            topic: 'Matemáticas',
            count: 3,
          );

          expect(response.isNotEmpty, true);
          final lower = response.toLowerCase();
          expect(
            lower.contains('frente') || lower.contains('pregunta'),
            true,
            reason: 'Debe contener formato de flashcard',
          );
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test(
        'Nivel 5b: Generar flashcards tema MEP',
        () async {
          final response = await client.generateFlashcards(
            topic: 'Álgebra - Ecuaciones lineales',
            count: 5,
          );

          expect(response.isNotEmpty, true);
          print('Flashcards generadas: ${response.substring(0, 200)}');
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test(
        'Nivel 5c: Generar flashcards tema científico',
        () async {
          final response = await client.generateFlashcards(
            topic: 'Biología - Célula',
            count: 5,
          );

          expect(response.isNotEmpty, true);
          expect(response.length, greaterThan(50));
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test(
        'Nivel 5d: Flashcards con contenido largo',
        () async {
          final response = await client.generateFlashcards(
            topic: 'Historia de Costa Rica - Época precolombina',
            count: 3,
          );

          expect(response.isNotEmpty, true);
          final cards = client.parseFlashcards(response);
          print('Parseadas: ${cards.length} flashcards');
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test(
        'Nivel 5e: Flashcards inglés (debe rechazar)',
        () async {
          final response = await client.generateFlashcards(
            topic: 'English vocabulary',
            count: 3,
          );

          expect(response.isNotEmpty, true);
          final cards = client.parseFlashcards(response);
          if (cards.isNotEmpty) {
            for (final card in cards) {
              expect(card['front']!.toLowerCase(), isNot(contains('the')));
            }
          }
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );
    });

    group('Nivel 6: Quiz Generation - Parsing', () {
      test(
        'Quiz con formato estándar A) B) C) D)',
        () async {
          final response = await client.generateQuiz(
            content: 'El agua hierve a 100°C. El hielo funde a 0°C.',
            numQuestions: 2,
          );

          expect(response.isNotEmpty, true);
          final lower = response.toLowerCase();
          expect(lower.contains('pregunta'), true);
          expect(lower.contains('a)') || lower.contains('a)'), true);
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test('Quiz con 5 preguntas', () async {
        final response = await client.generateQuiz(
          content:
              'La Tierra es el tercer planeta. Marte es el cuarto. Júpiter es el quinto.',
          numQuestions: 5,
        );

        expect(response.isNotEmpty, true);
        final preguntaCount = 'pregunta'
            .allMatches(response.toLowerCase())
            .length;
        expect(preguntaCount, 5);
      }, timeout: const Timeout(Duration(minutes: 1)));

      test('Quiz tema específico MEP', () async {
        final response = await client.generateQuiz(
          content: 'Teorema de Pitágoras: a² + b² = c²',
          numQuestions: 3,
        );

        expect(response.isNotEmpty, true);
        print('Quiz: ${response.substring(0, 300)}');
      }, timeout: const Timeout(Duration(minutes: 1)));
    });

    group('Nivel 7: Exámenes MEP - Generación JSON', () {
      test(
        'MEP Matemáticas 10° - Álgebra',
        () async {
          final response = await client.generateNewQuestions(
            subject: 'Matemáticas',
            level: 10,
            count: 5,
            topics: ['Álgebra', 'Ecuaciones'],
          );

          expect(response.isNotEmpty, true);
          expect(response.contains('['), true, reason: 'Debe contener JSON');

          final jsonStart = response.indexOf('[');
          final jsonEnd = response.lastIndexOf(']');
          expect(jsonEnd, greaterThan(jsonStart));

          final jsonStr = response.substring(jsonStart, jsonEnd + 1);
          final List<dynamic> preguntas = jsonDecode(jsonStr);

          expect(preguntas.length, 5);
          expect(preguntas[0]['question'], isNotNull);
          expect(preguntas[0]['options'], isA<List>());
          expect((preguntas[0]['options'] as List).length, 4);
          expect(preguntas[0]['correctIndex'], isA<int>());
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test('MEP Ciencias 10° - Biología', () async {
        final response = await client.generateNewQuestions(
          subject: 'Ciencias',
          level: 10,
          count: 5,
          topics: ['Célula', 'Fotosíntesis'],
        );

        expect(response.isNotEmpty, true);
        final preguntas = _parseJsonQuestions(response);
        expect(preguntas.length, 5);
      }, timeout: const Timeout(Duration(minutes: 1)));

      test('MEP Estudios Sociales', () async {
        final response = await client.generateNewQuestions(
          subject: 'Estudios Sociales',
          level: 10,
          count: 5,
          topics: ['Historia de Costa Rica'],
        );

        expect(response.isNotEmpty, true);
      }, timeout: const Timeout(Duration(minutes: 1)));

      test('MEP Español - Gramática', () async {
        final response = await client.generateNewQuestions(
          subject: 'Español',
          level: 10,
          count: 5,
          topics: ['Gramática', 'Ortografía'],
        );

        expect(response.isNotEmpty, true);
      }, timeout: const Timeout(Duration(minutes: 1)));

      test(
        'MEP 11° Año - Nivel avanzado',
        () async {
          final response = await client.generateNewQuestions(
            subject: 'Matemáticas',
            level: 11,
            count: 5,
            topics: ['Funciones', 'Límites'],
          );

          expect(response.isNotEmpty, true);
        },
        timeout: const Timeout(Duration(minutes: 1)),
      );

      test('MEP 12° Año - Preparatoria', () async {
        final response = await client.generateNewQuestions(
          subject: 'Matemáticas',
          level: 12,
          count: 5,
          topics: ['Cálculo', 'Derivadas'],
        );

        expect(response.isNotEmpty, true);
      }, timeout: const Timeout(Duration(minutes: 1)));

      test(
        'Examen completo - Todos los temas',
        () async {
          final response = await client.generateNewQuestions(
            subject: 'Matemáticas',
            level: 10,
            count: 10,
            topics: [
              'Álgebra',
              'Geometría',
              'Trigonometría',
              'Estadística',
              'Funciones',
            ],
          );

          expect(response.isNotEmpty, true);
          final preguntas = _parseJsonQuestions(response);
          expect(preguntas.length, 10);

          for (final p in preguntas) {
            expect(p['question'], isNotNull);
            expect(p['options'], isA<List>());
            expect(p['correctIndex'], isA<int>());
            expect(p['explanation'], isNotNull);
            expect(p['topic'], isNotNull);
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    });
  });
}

List<Map<String, dynamic>> _parseJsonQuestions(String response) {
  final firstBracket = response.indexOf('[');
  final lastBracket = response.lastIndexOf(']');

  if (firstBracket == -1 || lastBracket == -1) {
    return [];
  }

  final jsonStr = response.substring(firstBracket, lastBracket + 1);

  try {
    final List<dynamic> data = jsonDecode(jsonStr);
    return data.cast<Map<String, dynamic>>();
  } catch (e) {
    return [];
  }
}
