import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

void main() {
  group('GroqClient - Content Filtering', () {
    late GroqClient client;

    setUp(() {
      client = GroqClient(apiKey: 'test-api-key');
    });

    group('containsBlockedContent', () {
      test('should detect blocked hacking-related content', () {
        expect(client.containsBlockedContent('hackear un sistema'), isTrue);
        expect(client.containsBlockedContent('cómo hackear'), isTrue);
        expect(client.containsBlockedContent('HACKEAR'), isTrue);
      });

      test('should detect blocked stealing-related content', () {
        expect(client.containsBlockedContent('robar información'), isTrue);
        expect(client.containsBlockedContent('como robar'), isTrue);
      });

      test('should detect blocked security attack content', () {
        expect(client.containsBlockedContent('ataque ddos'), isTrue);
        expect(client.containsBlockedContent('phishing'), isTrue);
        expect(client.containsBlockedContent('DDOS'), isTrue);
      });

      test('should detect blocked malware-related content', () {
        expect(client.containsBlockedContent('crear virus'), isTrue);
        expect(client.containsBlockedContent('malware'), isTrue);
        expect(client.containsBlockedContent('exploit'), isTrue);
      });

      test('should detect blocked credential theft content', () {
        expect(client.containsBlockedContent('contraseña robada'), isTrue);
        expect(client.containsBlockedContent('robar contraseñas'), isTrue);
      });

      test('should detect blocked learning harmful activities', () {
        expect(client.containsBlockedContent('aprender a robar'), isTrue);
      });

      test('should detect blocked weapon-related content', () {
        expect(client.containsBlockedContent('como hacer una bomba'), isTrue);
        expect(client.containsBlockedContent('fabricar armas'), isTrue);
      });

      test('should detect blocked prank content', () {
        expect(client.containsBlockedContent('broma pesada'), isTrue);
      });

      test('should allow normal study content', () {
        expect(client.containsBlockedContent('matemáticas'), isFalse);
        expect(
          client.containsBlockedContent('historia de Costa Rica'),
          isFalse,
        );
        expect(client.containsBlockedContent('flashcards'), isFalse);
        expect(client.containsBlockedContent('resumen del capítulo'), isFalse);
      });

      test('should be case insensitive', () {
        expect(client.containsBlockedContent('HACKEAR'), isTrue);
        expect(client.containsBlockedContent('Hackear'), isTrue);
        expect(client.containsBlockedContent('HaCkEaR'), isTrue);
      });
    });

    group('getSafeResponse', () {
      test('should return a safe response message', () {
        final response = client.getSafeResponse('any message');

        expect(response, contains('Lo siento'));
        expect(response, contains('estudio'));
        expect(response, contains('Resumir'));
        expect(response, contains('flashcards'));
      });
    });
  });

  group('GroqClient - Flashcard Parsing', () {
    late GroqClient client;

    setUp(() {
      client = GroqClient(apiKey: 'test-api-key');
    });

    test('should parse flashcards with Frente/Dorso format', () {
      final response = '''
Frente: ¿Qué es la fotosíntesis?
Dorso: Proceso por el cual las plantas convierten luz en energía

Frente: ¿Quién descubrió América?
Dorso: Cristóbal Colón en 1492
''';

      final cards = client.parseFlashcards(response);

      expect(cards.length, 2);
      expect(cards[0]['front'], '¿Qué es la fotosíntesis?');
      expect(
        cards[0]['back'],
        'Proceso por el cual las plantas convierten luz en energía',
      );
      expect(cards[1]['front'], '¿Quién descubrió América?');
      expect(cards[1]['back'], 'Cristóbal Colón en 1492');
    });

    test('should parse flashcards with Pregunta/Respuesta format', () {
      final response = '''
Pregunta: ¿Capital de Francia?
Respuesta: París

Pregunta: ¿Mayor océano?
Respuesta: Pacífico
''';

      final cards = client.parseFlashcards(response);

      expect(cards.length, 2);
      expect(cards[0]['front'], '¿Capital de Francia?');
      expect(cards[0]['back'], 'París');
    });

    test('should return empty list for invalid format', () {
      final response = 'This is not a flashcard format';

      final cards = client.parseFlashcards(response);

      expect(cards, isEmpty);
    });

    test('should handle incomplete flashcards', () {
      final response = '''
Frente: ¿Solo frente?
''';

      final cards = client.parseFlashcards(response);

      expect(cards, isEmpty);
    });
  });

  group('GroqException', () {
    test('should format error message correctly', () {
      final exception = GroqException(
        message: 'Invalid API key',
        statusCode: 401,
      );

      expect(exception.toString(), contains('GroqException'));
      expect(exception.toString(), contains('Invalid API key'));
      expect(exception.toString(), contains('401'));
    });

    test('should handle null status code', () {
      final exception = GroqException(message: 'Network error');

      expect(exception.statusCode, isNull);
      expect(exception.toString(), contains('Network error'));
    });
  });
}
