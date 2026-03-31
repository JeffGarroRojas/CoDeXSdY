import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/gemini_client.dart';

void main() {
  group('Gemini Client - Tests de Verificación', () {
    late GeminiClient client;

    setUp(() {
      client = GeminiClient();
    });

    test('1. Chat básico', () async {
      final response = await client.chat(
        messages: [
          {'role': 'user', 'content': 'Di hola en una palabra'},
        ],
        maxTokens: 50,
      );
      expect(response.isNotEmpty, true);
      print('Chat: $response');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('2. Resumen', () async {
      final response = await client.generateSummary(
        content:
            'La fotosíntesis es el proceso por el cual las plantas, algas y algunas bacterias convierten la luz solar en energía química. Este proceso es fundamental para la vida en la Tierra ya que produce oxígeno y glucosa.',
        maxTokens: 200,
      );
      expect(response.isNotEmpty, true);
      print(
        'Resumen: ${response.length > 50 ? response.substring(0, 50) : response}...',
      );
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('3. Flashcards', () async {
      final response = await client.generateFlashcards(
        topic: 'Matemáticas',
        count: 2,
      );
      expect(response.isNotEmpty, true);
      print(
        'Flashcards: ${response.length > 100 ? response.substring(0, 100) : response}...',
      );
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('4. Quiz', () async {
      final response = await client.generateQuiz(
        content:
            'El agua es H2O. Es un compuesto químico formado por hidrógeno y oxígeno.',
        numQuestions: 2,
      );
      expect(response.isNotEmpty, true);
      print(
        'Quiz: ${response.length > 100 ? response.substring(0, 100) : response}...',
      );
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('5. Preguntas MEP', () async {
      final response = await client.generateNewQuestions(
        subject: 'Matemáticas',
        level: 10,
        count: 2,
        topics: ['Álgebra'],
      );
      expect(response.isNotEmpty, true);
      expect(response.contains('['), true);
      print(
        'Preguntas: ${response.length > 100 ? response.substring(0, 100) : response}...',
      );
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
