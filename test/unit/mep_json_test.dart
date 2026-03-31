import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

void main() {
  group('MEP Exam JSON Generation', () {
    test('PROMPT_MEP_JSON contiene las instrucciones correctas', () {
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('MEP'),
        isTrue,
        reason: 'El prompt debe mencionar MEP',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('JSON'),
        isTrue,
        reason: 'El prompt debe mencionar JSON',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('12.°'),
        isTrue,
        reason: 'El prompt debe ser para 12.° año',
      );
    });

    test('PROMPT_MEP_JSON especifica formato JSON puro', () {
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('['),
        isTrue,
        reason: 'Debe indicar que el primer carácter es [',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains(']'),
        isTrue,
        reason: 'Debe indicar que el último carácter es ]',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('No uses ```json'),
        isTrue,
        reason: 'Debe indicar que NO use markdown',
      );
    });

    test('PROMPT_MEP_JSON contiene esquema de datos', () {
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('question'),
        isTrue,
        reason: 'Debe incluir campo question',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('options'),
        isTrue,
        reason: 'Debe incluir campo options',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('correctIndex'),
        isTrue,
        reason: 'Debe incluir campo correctIndex',
      );
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('explanation'),
        isTrue,
        reason: 'Debe incluir campo explanation',
      );
    });

    test('PROMPT_MEP_JSON menciona a CoDy en explicaciones', () {
      expect(
        GroqClient.PROMPT_MEP_JSON.contains('CoDy'),
        isTrue,
        reason: 'Las explicaciones deben mencionar a CoDy',
      );
    });
  });

  group('JSON Parser Logic', () {
    test('Parser extrae array JSON correctamente', () {
      const response = '''Antes del JSON
[
  {"question": "Test?", "options": ["A", "B", "C", "D"], "correctIndex": 0, "explanation": "Test", "topic": "Test"}
]
Después del JSON''';

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      expect(jsonStart, greaterThan(-1));
      expect(jsonEnd, greaterThan(jsonStart));
      expect(response.substring(jsonStart, jsonEnd), contains('"question"'));
    });

    test('Parser maneja respuesta sin JSON', () {
      const response = 'Esta es una respuesta sin JSON válido';

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      expect(jsonStart, equals(-1));
      expect(jsonEnd, equals(0));
    });

    test('Parser maneja JSON incompleto', () {
      const response = '''[
  {"question": "Test?", "options": ["A", "B", "C", "D"]
''';

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      expect(jsonStart, greaterThan(-1));
      expect(response.substring(jsonStart, jsonEnd), isNot(contains('}')));
    });
  });

  group('Timer Proporcional', () {
    test('Timer calcula correctamente para 50 preguntas', () {
      const preguntas = 50;
      const tiempoPorPregunta = 1.8;
      final segundos = (preguntas * tiempoPorPregunta * 60).round();

      expect(segundos, equals(5400), reason: '50 preguntas = 90 minutos');
      expect(segundos / 60, equals(90), reason: '90 minutos');
    });

    test('Timer calcula correctamente para 10 preguntas', () {
      const preguntas = 10;
      const tiempoPorPregunta = 1.8;
      final segundos = (preguntas * tiempoPorPregunta * 60).round();

      expect(segundos, equals(1080), reason: '10 preguntas = 18 minutos');
      expect(segundos / 60, equals(18), reason: '18 minutos');
    });

    test('Timer calcula correctamente para 20 preguntas', () {
      const preguntas = 20;
      const tiempoPorPregunta = 1.8;
      final segundos = (preguntas * tiempoPorPregunta * 60).round();

      expect(segundos, equals(2160), reason: '20 preguntas = 36 minutos');
      expect(segundos / 60, equals(36), reason: '36 minutos');
    });
  });
}
