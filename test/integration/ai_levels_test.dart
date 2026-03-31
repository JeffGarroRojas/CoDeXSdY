import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/ai_client.dart';

void main() {
  final aiClient = AIClient();

  test('Nivel 1: Chat básico', () async {
    final response = await aiClient.chat(
      messages: [
        {'role': 'system', 'content': 'Responde solo con "OK"'},
        {'role': 'user', 'content': 'Hola'},
      ],
    );
    print('Nivel 1 OK: $response');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 2: Resumen', () async {
    final response = await aiClient.generateSummary(
      content:
          'La fotosíntesis es el proceso por el cual las plantas convierten luz en energía.',
    );
    print('Nivel 2 OK: ${response.substring(0, 50)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 3: Flashcards', () async {
    final response = await aiClient.generateFlashcards(
      topic: 'Matemáticas básicas',
      count: 3,
    );
    print('Nivel 3 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 4: Quiz', () async {
    final response = await aiClient.generateQuiz(
      content:
          'La capital de Francia es París. La capital de España es Madrid.',
      numQuestions: 2,
    );
    print('Nivel 4 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 5: Preguntas tipo examen', () async {
    final response = await aiClient.chat(
      messages: [
        {
          'role': 'system',
          'content':
              'Genera 3 preguntas de opción múltiple sobre matemáticas básicas. Formato: Pregunta: ... A)... B)... C)... D)... Respuesta: ',
        },
        {'role': 'user', 'content': 'Genera preguntas de matemáticas'},
      ],
    );
    print('Nivel 5 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 6: Matemáticas MEP 10°', () async {
    final response = await aiClient.generateNewQuestions(
      subject: 'Matemáticas',
      level: 10,
      count: 5,
      topics: ['Álgebra', 'Ecuaciones'],
    );
    print('Nivel 6 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 7: Ciencias MEP', () async {
    final response = await aiClient.generateNewQuestions(
      subject: 'Ciencias',
      level: 9,
      count: 5,
      topics: ['Célula', 'Fotosíntesis'],
    );
    print('Nivel 7 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 8: Estudios Sociales MEP', () async {
    final response = await aiClient.generateNewQuestions(
      subject: 'Estudios Sociales',
      level: 8,
      count: 5,
      topics: ['Historia de Costa Rica', 'Geografía'],
    );
    print('Nivel 8 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 9: Español MEP', () async {
    final response = await aiClient.generateNewQuestions(
      subject: 'Español',
      level: 7,
      count: 5,
      topics: ['Gramática', 'Ortografía'],
    );
    print('Nivel 9 OK: ${response.substring(0, 100)}...');
    expect(response.isNotEmpty, true);
  });

  test('Nivel 10: Examen completo MEP', () async {
    final response = await aiClient.chat(
      messages: [
        {
          'role': 'system',
          'content':
              'Genera un examen de 10 preguntas de opción múltiple para 10° año de matemáticas en Costa Rica (MEP). Incluye temas de álgebra y geometría.',
        },
        {'role': 'user', 'content': 'Genera el examen'},
      ],
    );
    print('Nivel 10 OK: ${response.substring(0, 150)}...');
    expect(response.isNotEmpty, true);
  });
}
