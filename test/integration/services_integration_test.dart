import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/validation_service.dart';
import 'package:codex_sdy/core/services/retry_service.dart';
import 'package:codex_sdy/core/services/rate_limiter.dart';
import 'package:codex_sdy/core/services/circuit_breaker.dart';
import 'package:codex_sdy/features/quiz/data/models/question.dart';
import 'package:codex_sdy/features/flashcards/data/models/flashcard.dart';

void main() {
  group('Flashcard Creation Flow', () {
    test('should create flashcard with valid data', () {
      final flashcard = Flashcard.create(
        odId: 'test_1',
        front: '¿Qué es Flutter?',
        back: 'Un framework de Google',
        userId: 'test_user',
      );

      expect(flashcard.odId, 'test_1');
      expect(flashcard.front, '¿Qué es Flutter?');
      expect(flashcard.back, 'Un framework de Google');
      expect(flashcard.userId, 'test_user');
      expect(flashcard.status, FlashcardStatus.newCard);
    });

    test('should convert flashcard to map correctly', () {
      final flashcard = Flashcard.create(
        odId: 'test_2',
        front: 'Test front',
        back: 'Test back',
        userId: 'test_user',
      );

      final map = flashcard.toMap();

      expect(map['odId'], 'test_2');
      expect(map['front'], 'Test front');
      expect(map['back'], 'Test back');
      expect(map['userId'], 'test_user');
    });

    test('should create flashcard from map correctly', () {
      final map = {
        'odId': 'test_3',
        'front': 'From map front',
        'back': 'From map back',
        'userId': 'test_user',
        'documentId': null,
        'tags': <String>[],
        'status': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'nextReview': null,
        'easeFactor': 2.5,
        'interval': 0,
        'repetitions': 0,
      };

      final flashcard = Flashcard.fromMap(map);

      expect(flashcard.odId, 'test_3');
      expect(flashcard.front, 'From map front');
      expect(flashcard.back, 'From map back');
    });
  });

  group('QuizResult Creation Flow', () {
    test('should create quiz result with correct data', () {
      final result = QuizResult.create(
        odId: 'quiz_1',
        userId: 'test_user',
        totalQuestions: 10,
        correctAnswers: 8,
        levelIndex: 0,
        categoryIndex: 0,
        durationSeconds: 300,
        userAnswers: [0, 1, 2, 1, 0, 2, 1, 0, 1, 2],
      );

      expect(result.odId, 'quiz_1');
      expect(result.totalQuestions, 10);
      expect(result.correctAnswers, 8);
      expect(result.percentage, 80.0);
      expect(result.passed, isTrue);
    });

    test('should calculate percentage correctly', () {
      final result = QuizResult.create(
        odId: 'quiz_2',
        userId: 'test_user',
        totalQuestions: 5,
        correctAnswers: 2,
        levelIndex: 0,
        categoryIndex: 0,
        durationSeconds: 120,
        userAnswers: [0, 1, 2, 1, 0],
      );

      expect(result.percentage, 40.0);
      expect(result.passed, isFalse);
    });
  });

  group('Question Model Flow', () {
    test('should create question correctly', () {
      final question = Question.create(
        odId: 'q_1',
        question: '¿Cuánto es 2+2?',
        options: ['3', '4', '5', '6'],
        correctAnswerIndex: 1,
        explanation: '2+2=4',
        categoryIndex: 0,
        levelIndex: 0,
        topic: 'Matemáticas',
      );

      expect(question.odId, 'q_1');
      expect(question.question, '¿Cuánto es 2+2?');
      expect(question.options.length, 4);
      expect(question.correctAnswerIndex, 1);
      expect(question.isCorrect(1), isTrue);
      expect(question.isCorrect(0), isFalse);
    });

    test('should get correct answer text', () {
      final question = Question.create(
        odId: 'q_2',
        question: 'Capital de Francia?',
        options: ['Londres', 'París', 'Madrid', 'Berlín'],
        correctAnswerIndex: 1,
        explanation: 'París es la capital de Francia',
        categoryIndex: 0,
        levelIndex: 0,
        topic: 'Geografía',
      );

      expect(question.correctAnswer, 'París');
    });
  });

  group('Validation Service Integration', () {
    late ValidationService validationService;

    setUp(() {
      validationService = ValidationService.instance;
    });

    test('should validate flashcard data end-to-end', () {
      final frontError = validationService.validateFlashcardFront(
        'Test front content',
      );
      expect(frontError, isNull);

      final backError = validationService.validateFlashcardBack(
        'Test back content',
      );
      expect(backError, isNull);
    });

    test('should validate topic correctly', () {
      final validTopic = validationService.validateTopic('Matemáticas');
      expect(validTopic, isNull);

      final invalidTopic = validationService.validateTopic('');
      expect(invalidTopic, isNotNull);
    });

    test('should calculate password strength correctly', () {
      final emptyStrength = ValidationService.calculatePasswordStrength('');
      expect(emptyStrength, 0);

      final weakStrength = ValidationService.calculatePasswordStrength('123');
      expect(weakStrength, lessThan(50));

      final strongStrength = ValidationService.calculatePasswordStrength(
        'MyP@ssw0rd123!',
      );
      expect(strongStrength, greaterThan(weakStrength));
    });
  });

  group('Retry Service Integration', () {
    test('should retry failed operation', () async {
      int attempts = 0;

      final result = await RetryService.execute(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary error');
          }
          return 'Success';
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
        shouldRetry: (error) => error.toString().contains('error'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success');
      expect(attempts, 3);
    });

    test('should fail after max attempts', () async {
      final result = await RetryService.execute(
        () async => throw Exception('Permanent error'),
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        shouldRetry: (error) => error.toString().contains('Temporary'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.attempts, greaterThan(0));
    });
  });

  group('Rate Limiter Integration', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter.instance;
      rateLimiter.resetAll();
    });

    test('should limit API calls', () {
      rateLimiter.registerBucket(
        'api_test',
        const RateLimitConfig(
          maxRequests: 2,
          windowDuration: Duration(minutes: 1),
        ),
      );

      expect(rateLimiter.checkLimit('api_test').allowed, isTrue);
      expect(rateLimiter.checkLimit('api_test').allowed, isTrue);
      expect(rateLimiter.checkLimit('api_test').allowed, isFalse);
    });

    test('should allow different buckets independently', () {
      rateLimiter.registerBucket(
        'bucket_a',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );
      rateLimiter.registerBucket(
        'bucket_b',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );

      rateLimiter.checkLimit('bucket_a');
      expect(rateLimiter.isBucketAvailable('bucket_a'), isFalse);
      expect(rateLimiter.isBucketAvailable('bucket_b'), isTrue);
    });
  });

  group('Circuit Breaker Integration', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker();
    });

    test('should open after threshold failures', () async {
      for (int i = 0; i < 5; i++) {
        await circuitBreaker.execute(() async => throw Exception('Error'));
      }

      expect(circuitBreaker.isOpen, isTrue);
    });

    test('should allow success after reset', () async {
      for (int i = 0; i < 5; i++) {
        await circuitBreaker.execute(() async => throw Exception('Error'));
      }

      circuitBreaker.reset();

      final result = await circuitBreaker.execute(() async => 'Success');

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success');
      expect(circuitBreaker.isClosed, isTrue);
    });
  });

  group('Cross-Service Integration', () {
    test('should work with circuit breaker', () async {
      final circuitBreaker = CircuitBreaker();

      final result = await circuitBreaker.execute(() async {
        return 'Success after reset';
      });

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success after reset');
    });
  });
}
