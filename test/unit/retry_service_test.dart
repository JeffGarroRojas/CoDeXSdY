import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/retry_service.dart';

void main() {
  group('RetryService', () {
    test('should succeed on first attempt', () async {
      final operation = () async => 'Success';

      final result = await RetryService.execute(operation);

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success');
      expect(result.attempts, 1);
    });

    test('should retry on failure and eventually succeed', () async {
      int attempt = 0;
      final operation = () async {
        attempt++;
        if (attempt < 3) {
          throw Exception('Temporary error');
        }
        return 'Success after retries';
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success after retries');
      expect(result.attempts, 3);
    });

    test('should fail after max attempts', () async {
      final operation = () async {
        throw Exception('Persistent error');
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.attempts, 3);
    });

    test('should respect retryable status codes', () async {
      final operation = () async {
        throw Exception('Network timeout');
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.attempts, 3);
    });

    test('should use custom shouldRetry function', () async {
      int callCount = 0;
      final operation = () async {
        callCount++;
        if (callCount < 2) {
          throw Exception('Retryable error');
        }
        return 'Success';
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
        shouldRetry: (error) {
          return error.toString().contains('Retryable');
        },
      );

      expect(result.isSuccess, isTrue);
      expect(result.attempts, 2);
    });

    test('should call onRetry callback', () async {
      int callCount = 0;
      final retries = <int>[];
      final operation = () async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Error $callCount');
        }
        return 'Success';
      };

      await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
        onRetry: (attempt, error) {
          retries.add(attempt);
        },
      );

      expect(retries, [1, 2]);
    });

    test('should track total duration', () async {
      final operation = () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'Success';
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.totalDuration.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('should handle different return types', () async {
      final intOp = () async => 42;
      final listOp = () async => [1, 2, 3];
      final mapOp = () async => {'key': 'value'};

      final intResult = await RetryService.execute(intOp);
      final listResult = await RetryService.execute(listOp);
      final mapResult = await RetryService.execute(mapOp);

      expect(intResult.data, 42);
      expect(listResult.data, [1, 2, 3]);
      expect(mapResult.data, {'key': 'value'});
    });

    test('should record all attempts', () async {
      int callCount = 0;
      final operation = () async {
        callCount++;
        throw Exception('Error $callCount');
      };

      final result = await RetryService.execute(
        operation,
        config: const RetryConfig(
          maxAttempts: 4,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(result.attempts, 4);
      expect(callCount, 4);
    });
  });

  group('RetryConfig', () {
    test('should have sensible defaults', () {
      const config = RetryConfig();

      expect(config.maxAttempts, 3);
      expect(config.initialDelay, const Duration(milliseconds: 500));
      expect(config.maxDelay, const Duration(seconds: 10));
      expect(config.strategy, RetryStrategy.exponential);
      expect(config.backoffMultiplier, 2.0);
    });

    test('should create copy with modifications', () {
      const original = RetryConfig(
        maxAttempts: 5,
        initialDelay: Duration(seconds: 1),
      );

      final modified = original.copyWith(
        maxAttempts: 10,
        strategy: RetryStrategy.linear,
      );

      expect(modified.maxAttempts, 10);
      expect(modified.initialDelay, const Duration(seconds: 1));
      expect(modified.strategy, RetryStrategy.linear);
    });

    test('forQuickRetries should have short delays', () {
      final config = RetryService.forQuickRetries();

      expect(config.maxAttempts, 3);
      expect(config.initialDelay, const Duration(milliseconds: 200));
      expect(config.maxDelay, const Duration(seconds: 2));
      expect(config.backoffMultiplier, 1.5);
    });

    test('forNetworkCalls should have longer delays', () {
      final config = RetryService.forNetworkCalls();

      expect(config.maxAttempts, 5);
      expect(config.initialDelay, const Duration(seconds: 1));
      expect(config.maxDelay, const Duration(seconds: 30));
      expect(config.backoffMultiplier, 2.0);
    });
  });

  group('RetryResult', () {
    test('should create success result', () {
      final result = RetryResult<String>(
        data: 'Success',
        isSuccess: true,
        attempts: 1,
        totalDuration: const Duration(milliseconds: 100),
      );

      expect(result.data, 'Success');
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.attempts, 1);
      expect(result.totalDuration, const Duration(milliseconds: 100));
    });

    test('should create failure result', () {
      final error = Exception('Test error');
      final result = RetryResult<String>(
        error: error,
        isSuccess: false,
        attempts: 3,
        totalDuration: const Duration(milliseconds: 500),
      );

      expect(result.data, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.error, error);
      expect(result.attempts, 3);
    });
  });
}
