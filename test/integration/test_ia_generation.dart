import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

void main() {
  final envFile = File('.env');
  final content = envFile.readAsStringSync();
  final match = RegExp(r'GROQ_API_KEY=(.+)').firstMatch(content);
  final apiKey = match?.group(1)?.trim();

  group('Generación de contenido IA', () {
    late GroqClient client;

    setUp(() {
      if (apiKey != null) {
        client = GroqClient(apiKey: apiKey);
      }
    });

    test(
      'Generar flashcards sobre matemáticas',
      () async {
        if (apiKey == null) {
          markTestSkipped('No API key');
          return;
        }

        final response = await client.generateFlashcards(
          topic: 'Matemáticas básicas',
          count: 3,
        );

        expect(response, isNotEmpty);
        print('Flashcards:\n$response');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    test('Generar preguntas de quiz', () async {
      if (apiKey == null) {
        markTestSkipped('No API key');
        return;
      }

      final response = await client.generateQuiz(
        content:
            'La fotosíntesis es el proceso por el cual las plantas convierten luz en energía. El agua es H2O.',
        numQuestions: 2,
      );

      expect(response, isNotEmpty);
      print('Quiz:\n$response');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test(
      'Generar nuevas preguntas para MEP',
      () async {
        if (apiKey == null) {
          markTestSkipped('No API key');
          return;
        }

        final response = await client.generateNewQuestions(
          subject: 'Matemáticas',
          level: 10,
          count: 3,
          topics: ['Álgebra', 'Geometría'],
        );

        expect(response, isNotEmpty);
        print('Preguntas MEP:\n$response');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
