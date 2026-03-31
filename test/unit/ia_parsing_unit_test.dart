import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tests de Parsing - Funciones Auxiliares', () {
    group('_extractJsonFromResponse (simulado)', () {
      test('caso 1: JSON con texto antes', () {
        const response = '''
Aquí tienes las preguntas:
[
  {"question": "Test", "options": ["A", "B"], "correctIndex": 0}
]
''';
        final result = _extractJsonFromResponse(response);
        expect(result.isNotEmpty, true);
        expect(result.contains('[{"question": "Test"'), true);
      });

      test('caso 2: JSON con texto después', () {
        const response = '''
[
  {"question": "Test", "options": ["A", "B"], "correctIndex": 0}
]
Gracias por usar el servicio.
''';
        final result = _extractJsonFromResponse(response);
        expect(result.isNotEmpty, true);
      });

      test('caso 3: JSON con texto antes y después', () {
        const response = '''
Antes del JSON
[
  {"question": "P1", "options": ["A", "B", "C", "D"], "correctIndex": 0}
]
Después del JSON
''';
        final result = _extractJsonFromResponse(response);
        expect(result.isNotEmpty, true);
      });

      test('caso 4: Sin corchetes - retorna vacío', () {
        const response = 'Esto no es JSON';
        final result = _extractJsonFromResponse(response);
        expect(result.isEmpty, true);
      });

      test('caso 5: Solo corchetes vacíos', () {
        const response = '[]';
        final result = _extractJsonFromResponse(response);
        expect(result, '[]');
      });

      test('caso 6: Múltiples arrays (toma el primero)', () {
        const response = '[1,2][3,4]';
        final result = _extractJsonFromResponse(response);
        expect(result, '[1,2]');
      });

      test('caso 7: JSON con caracteres de control', () {
        const response = '[\t\n{"question": "Test"}]';
        final result = _extractJsonFromResponse(response);
        expect(result.isNotEmpty, true);
      });

      test('caso 8: JSON anidado complejo - objeto no array', () {
        const response = '''
{
  "preguntas": [
    {"question": "Q1", "options": ["A", "B"]}
  ]
}
''';
        final result = _extractJsonFromResponse(response);
        expect(result.isNotEmpty, true, reason: 'Extrae algo');
      });
    });

    group('Parseo de preguntas JSON', () {
      test('parsea array de preguntas válido', () {
        const jsonStr = '''
[
  {
    "question": "¿Qué es la célula?",
    "options": ["Unidad básica", "Órgano", "Tejido", "Sistema"],
    "correctIndex": 0,
    "explanation": "La célula es la unidad básica",
    "topic": "Biología"
  }
]
''';
        final preguntas = _parseJsonArray(jsonStr);
        expect(preguntas.length, 1);
        expect(preguntas[0]['question'], '¿Qué es la célula?');
        expect((preguntas[0]['options'] as List).length, 4);
        expect(preguntas[0]['correctIndex'], 0);
      });

      test('maneja pregunta sin opciones', () {
        const jsonStr = '[{"question": "Solo pregunta"}]';
        final preguntas = _parseJsonArray(jsonStr);
        expect(preguntas.length, 1);
      });

      test('maneja correctIndex fuera de rango', () {
        const jsonStr = '''
[
  {"question": "Q", "options": ["A", "B"], "correctIndex": 5}
]
''';
        final preguntas = _parseJsonArray(jsonStr);
        expect(preguntas.length, 1);
      });

      test('maneja correctAnswer como string', () {
        const jsonStr = '''
[
  {"question": "Q", "options": ["A", "B", "C", "D"], "correctAnswer": "B"}
]
''';
        final preguntas = _parseJsonArray(jsonStr);
        expect(preguntas.length, 1);
      });

      test('maneja campos faltantes gracefully', () {
        const jsonStr = '[{"pregunta": "sin formato"}]';
        final preguntas = _parseJsonArray(jsonStr);
        expect(
          preguntas.length,
          1,
          reason: 'El campo "question" falta pero el JSON es válido',
        );
      });
    });

    group('Casos edge reales de la IA', () {
      test('IA añade "Aquí tienes" antes del JSON', () {
        const response = '''
¡Claro! Aquí tienes las preguntas en formato JSON:

[
  {"question": "¿Capital de Costa Rica?", "options": ["San José", "Cartago", "Heredia", "Alajuela"], "correctIndex": 0, "explanation": "San José es la capital", "topic": "Geografía"}
]

¿Te sirven?
''';
        final json = _extractJsonFromResponse(response);
        expect(json.isNotEmpty, true);

        final preguntas = _parseJsonArray(json);
        expect(preguntas.length, 1);
        expect(preguntas[0]['question'], contains('Costa Rica'));
      });

      test('IA responde con markdown', () {
        const response = '''```json
[
  {"question": "Test", "options": ["A", "B", "C", "D"], "correctIndex": 0}
]
```''';
        final json = _extractJsonFromResponse(response);
        expect(json.isNotEmpty, true);
      });

      test('IA responde con formato mezclado', () {
        const response = '''
Pregunta 1: ¿Qué es X?
A) Opción A
B) Opción B
C) Opción C
D) Opción D
Respuesta: A

[
  {"question": "JSON Q", "options": ["A", "B"], "correctIndex": 0}
]
''';
        final json = _extractJsonFromResponse(response);
        expect(json.isNotEmpty, true);
      });

      test('IA responde sin opción D', () {
        const response = '''
[
  {"question": "¿2+2?", "options": ["3", "4", "5"], "correctIndex": 1}
]
''';
        final preguntas = _parseJsonArray(response);
        expect(preguntas.length, 1);
        expect((preguntas[0]['options'] as List).length, 3);
      });
    });
  });
}

String _extractJsonFromResponse(String text) {
  final firstBracket = text.indexOf('[');
  final lastBracket = text.lastIndexOf(']');

  if (firstBracket == -1 || lastBracket == -1 || firstBracket > lastBracket) {
    return '';
  }

  String jsonStr = text.substring(firstBracket, lastBracket + 1);
  jsonStr = jsonStr.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  return jsonStr.trim();
}

List<Map<String, dynamic>> _parseJsonArray(String jsonStr) {
  if (jsonStr.isEmpty) return [];

  if (!jsonStr.trim().startsWith('[')) return [];

  try {
    final List<dynamic> data = jsonDecode(jsonStr);
    return data.cast<Map<String, dynamic>>();
  } catch (e) {
    return [];
  }
}
