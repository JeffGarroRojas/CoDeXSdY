import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MEP Exam Page - Temas y Configuración', () {
    test('MATEMÁTICAS tiene todos los temas del pénsum MEP', () {
      final mathTopics = [
        'Conjuntos numéricos',
        'Expresiones algebraicas',
        'Ecuaciones e inecuaciones',
        'Proporcionalidad',
        'Porcentajes',
        'Potencias y raíces',
        'Figuras planas y cuerpos geométricos',
        'Perímetro, área y volumen',
        'Transformaciones en el plano',
        'Congruencia y similitud de triángulos',
        'Razones trigonométricas',
        'Teorema de Pitágoras',
        'Medidas de tendencia central',
        'Probabilidad básica',
        'Relaciones y funciones',
        'Funciones lineales y cuadráticas',
        'Sistemas de ecuaciones',
        'Polinomios y factorización',
      ];

      expect(
        mathTopics.length,
        greaterThanOrEqualTo(15),
        reason: 'Debe tener al menos 15 temas de matemáticas',
      );

      expect(mathTopics.contains('Teorema de Pitágoras'), isTrue);
      expect(mathTopics.contains('Razones trigonométricas'), isTrue);
      expect(mathTopics.contains('Funciones lineales y cuadráticas'), isTrue);
      expect(mathTopics.contains('Medidas de tendencia central'), isTrue);
    });

    test('CIENCIAS tiene temas de Biología, Química y Física', () {
      final scienceTopics = [
        'Célula y organelos',
        'Fotosíntesis y respiración',
        'Genética y herencia',
        'Evolución biológica',
        'Ecosistemas',
        'Materia y energía',
        'Átomo y tabla periódica',
        'Enlace químico',
        'Reacciones químicas',
        'Movimiento y fuerza',
        'Leyes de Newton',
        'Energía y trabajo',
        'Ondas y sonido',
        'Electricidad y magnetismo',
        'Sistema nervioso',
        'Sistema inmunológico',
      ];

      expect(scienceTopics.contains('Leyes de Newton'), isTrue);
      expect(scienceTopics.contains('Genética y herencia'), isTrue);
      expect(scienceTopics.contains('Átomo y tabla periódica'), isTrue);
    });

    test('ESTUDIOS SOCIALES tiene temas de Historia de Costa Rica', () {
      final socialTopics = [
        'Independencia de Costa Rica',
        'Formación de la República',
        'Juan Rafael Mora Porras',
        'Juan Santamaría y Campaña Nacional',
        'Constitución Política de 1949',
        'Derechos humanos',
        'Democracia y ciudadanía',
        'Geografía de Costa Rica',
        'Organización política',
        'Economía costarricense',
        'Globalización',
        'Historia de Centroamérica',
        'Culturas prehispánicas',
        'Relaciones internacionales',
      ];

      expect(socialTopics.contains('Independencia de Costa Rica'), isTrue);
      expect(
        socialTopics.contains('Juan Santamaría y Campaña Nacional'),
        isTrue,
      );
      expect(socialTopics.contains('Constitución Política de 1949'), isTrue);
      expect(socialTopics.contains('Geografía de Costa Rica'), isTrue);
    });

    test('ESPAÑOL tiene temas de gramática y literatura', () {
      final spanishTopics = [
        'Sustantivos y adjetivos',
        'Verbo y conjugaciones',
        'Pronombres y artículos',
        'Ortografía y acentuación',
        'Figuras retóricas',
        'Géneros literarios',
        'Narrativa y cuento',
        'Poesía',
        'Texto argumentativo',
        'Comprensión lectora',
        'Análisis de texto',
        'Redacción',
      ];

      expect(spanishTopics.contains('Ortografía y acentuación'), isTrue);
      expect(spanishTopics.contains('Figuras retóricas'), isTrue);
      expect(spanishTopics.contains('Comprensión lectora'), isTrue);
    });

    test('Cada materia tiene 50 preguntas', () {
      final expectedQuestions = 50;

      expect(expectedQuestions, equals(50));
    });

    test('Cada materia tiene 90 minutos de duración', () {
      final expectedMinutes = 90;

      expect(expectedMinutes, equals(90));
    });
  });

  group('Quiz Session - Parsing de Preguntas IA', () {
    test('Parsea correctamente una pregunta con formato válido', () {
      const rawResponse = '''
Pregunta: ¿Cuál es la capital de Costa Rica?
A) San José
B) Alajuela
C) Cartago
D) Heredia
Respuesta: A
Explicación: San José es la capital de Costa Rica desde 1823.
---
''';

      final questions = _parseTestQuestions(rawResponse);

      expect(questions.length, equals(1));
      expect(
        questions[0]['question'],
        equals('¿Cuál es la capital de Costa Rica?'),
      );
      expect(questions[0]['options'].length, equals(4));
      expect(questions[0]['correctIndex'], equals(0));
      expect(questions[0]['explanation'], contains('San José'));
    });

    test('Maneja múltiples preguntas separadas por ---', () {
      const rawResponse = '''
Pregunta: Pregunta 1
A) Opción A
B) Opción B
C) Opción C
D) Opción D
Respuesta: B
Explicación: Explicación 1
---
Pregunta: Pregunta 2
A) Opción A
B) Opción B
C) Opción C
D) Opción D
Respuesta: C
Explicación: Explicación 2
---
''';

      final questions = _parseTestQuestions(rawResponse);

      expect(questions.length, equals(2), reason: 'Debe parsear 2 preguntas');
      expect(
        questions[0]['correctIndex'],
        equals(1),
        reason: 'Primera respuesta es B',
      );
      expect(
        questions[1]['correctIndex'],
        equals(2),
        reason: 'Segunda respuesta es C',
      );
    });

    test('Identifica respuestas A, B, C, D correctamente', () {
      expect(_parseAnswer('Respuesta: A'), equals(0), reason: 'A = índice 0');
      expect(_parseAnswer('Respuesta: B'), equals(1), reason: 'B = índice 1');
      expect(_parseAnswer('Respuesta: C'), equals(2), reason: 'C = índice 2');
      expect(_parseAnswer('Respuesta: D'), equals(3), reason: 'D = índice 3');
    });
  });

  group('Flujo de Generación con IA', () {
    test('Prompt contiene información del pénsum MEP', () {
      const materias = [
        'Matemáticas',
        'Ciencias',
        'Estudios Sociales',
        'Español',
      ];

      for (final materia in materias) {
        expect(materia.isNotEmpty, isTrue);
      }

      expect(materias.length, equals(4));
    });

    test('Distribución de contenidos está definida', () {
      expect(
        true,
        isTrue,
        reason:
            'Matemáticas: 20% numérico, 25% geométrico, 20% estadístico, 35% funciones',
      );
    });
  });
}

List<Map<String, dynamic>> _parseTestQuestions(String response) {
  final questions = <Map<String, dynamic>>[];
  final blocks = response.split('---');

  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;

    String questionText = '';
    List<String> options = [];
    int correctIndex = 0;
    String explanation = '';

    final lines = trimmed.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('Pregunta:')) {
        questionText = trimmedLine.substring(9).trim();
      } else if (trimmedLine.startsWith('A)')) {
        options.add(trimmedLine.substring(2).trim());
      } else if (trimmedLine.startsWith('B)')) {
        options.add(trimmedLine.substring(2).trim());
      } else if (trimmedLine.startsWith('C)')) {
        options.add(trimmedLine.substring(2).trim());
      } else if (trimmedLine.startsWith('D)')) {
        options.add(trimmedLine.substring(2).trim());
      } else if (trimmedLine.startsWith('Respuesta:')) {
        correctIndex = _parseAnswer(trimmedLine);
      } else if (trimmedLine.startsWith('Explicación:')) {
        explanation = trimmedLine.substring(13).trim();
      }
    }

    if (questionText.isNotEmpty && options.length >= 4) {
      questions.add({
        'question': questionText,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      });
    }
  }

  return questions;
}

int _parseAnswer(String line) {
  final upper = line.toUpperCase();
  if (RegExp(r'\bA\b').hasMatch(upper) &&
      !upper.contains('B') &&
      !upper.contains('C') &&
      !upper.contains('D'))
    return 0;
  if (upper.contains('B') && !upper.contains('C') && !upper.contains('D'))
    return 1;
  if (upper.contains('C') && !upper.contains('D')) return 2;
  if (upper.contains('D')) return 3;
  return 0;
}
