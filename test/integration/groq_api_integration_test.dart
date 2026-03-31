import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:codex_sdy/core/services/groq_client.dart';

String? getApiKeyFromEnv() {
  final envFile = File('.env');
  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    final match = RegExp(r'GROQ_API_KEY=(.+)').firstMatch(content);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

void main() {
  final testApiKey = getApiKeyFromEnv();

  group('Groq API Integration Tests', () {
    late GroqClient client;
    late Dio dio;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.groq.com/openai/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    });

    group('Level 1: Basic Connectivity', () {
      test('should reach Groq API endpoint with API key', () async {
        if (testApiKey == null) {
          markTestSkipped('API key not found in .env file');
          return;
        }

        final response = await dio.get(
          '/models',
          options: Options(headers: {'Authorization': 'Bearer $testApiKey'}),
        );

        expect(response.statusCode, 200);
        expect(response.data['data'], isNotEmpty);
      });

      test('should have valid API key from .env', () {
        if (testApiKey == null) {
          markTestSkipped('API key not found in .env file');
          return;
        }
        expect(
          testApiKey.startsWith('gsk_'),
          isTrue,
          reason: 'API key should start with gsk_',
        );
      });
    });

    group('Level 2: API Key Validation', () {
      test('should authenticate with valid API key', () async {
        if (testApiKey == null) {
          markTestSkipped('API key not found');
          return;
        }

        final response = await dio.get(
          '/models',
          options: Options(headers: {'Authorization': 'Bearer $testApiKey'}),
        );

        expect(response.statusCode, 200, reason: 'API key should be valid');
        expect(response.data['data'], isNotEmpty);
      });

      test('should reject invalid API key', () async {
        try {
          await dio.get(
            '/models',
            options: Options(
              headers: {'Authorization': 'Bearer invalid_key_123'},
            ),
          );
          fail('Should have thrown an exception');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 401);
        }
      });
    });

    group('Level 3: Full API Functionality', () {
      test(
        'should generate chat completion',
        () async {
          if (testApiKey == null) {
            markTestSkipped('API key not found');
            return;
          }

          client = GroqClient(apiKey: testApiKey);

          final response = await client.chat(
            messages: [
              {'role': 'system', 'content': 'Eres un asistente útil.'},
              {'role': 'user', 'content': 'Hola, ¿cómo estás?'},
            ],
            maxTokens: 50,
          );

          expect(response, isNotEmpty);
          expect(response.length, lessThan(500));
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('should generate summary', () async {
        if (testApiKey == null) {
          markTestSkipped('API key not found');
          return;
        }

        client = GroqClient(apiKey: testApiKey);

        final summary = await client.generateSummary(
          content: '''La fotosíntesis es el proceso por el cual las plantas,
          algas y algunas bacterias convierten la luz solar en energía química.
          Este proceso es fundamental para la vida en la Tierra ya que produce
          oxígeno y consume dióxido de carbono. Las plantas capturan la luz solar
          a través de la clorofila en sus células.''',
          maxTokens: 100,
        );

        expect(summary, isNotEmpty);
        final lowerSummary = summary.toLowerCase();
        expect(
          lowerSummary.contains('punto') ||
              lowerSummary.contains('resumen') ||
              lowerSummary.contains('proceso'),
          isTrue,
        );
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('should generate flashcards', () async {
        if (testApiKey == null) {
          markTestSkipped('API key not found');
          return;
        }

        client = GroqClient(apiKey: testApiKey);

        final response = await client.generateFlashcards(
          topic: 'Matemáticas básicas',
          count: 3,
        );

        expect(response, isNotEmpty);
        final lowerResponse = response.toLowerCase();
        expect(
          lowerResponse.contains('frente') ||
              lowerResponse.contains('pregunta'),
          isTrue,
        );
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('should generate quiz', () async {
        if (testApiKey == null) {
          markTestSkipped('API key not found');
          return;
        }

        client = GroqClient(apiKey: testApiKey);

        final quiz = await client.generateQuiz(
          content:
              '''El agua es una sustancia compuesta por hidrógeno y oxígeno.
          Es esencial para la vida y cubre aproximadamente el 71% de la superficie
          terrestre. El agua puede existir en tres estados: sólido (hielo),
          líquido y gaseoso (vapor).''',
          numQuestions: 2,
        );

        expect(quiz, isNotEmpty);
        expect(quiz.toLowerCase(), contains('pregunta'));
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('should block inappropriate content', () {
        client = GroqClient(apiKey: 'test-key');

        expect(client.containsBlockedContent('hackear un sistema'), isTrue);
        expect(client.containsBlockedContent('robar información'), isTrue);
        expect(client.containsBlockedContent('ddos'), isTrue);
      });

      test(
        'should handle network errors gracefully',
        () async {
          if (testApiKey == null) {
            markTestSkipped('API key not found');
            return;
          }

          client = GroqClient(apiKey: testApiKey);

          try {
            await client.chat(
              messages: [
                {'role': 'user', 'content': 'Test message'},
              ],
              maxTokens: 5,
            );
          } on GroqException catch (e) {
            expect(e.message, isNotEmpty);
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    });
  });
}
