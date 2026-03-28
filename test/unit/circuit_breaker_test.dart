import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/circuit_breaker.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker();
    });

    test('should start in closed state', () {
      expect(circuitBreaker.state, CircuitState.closed);
      expect(circuitBreaker.isClosed, isTrue);
    });

    test('should transition to open after threshold failures', () async {
      final operation = () async {
        throw Exception('Test error');
      };

      for (int i = 0; i < 5; i++) {
        await circuitBreaker.execute(operation);
      }

      expect(circuitBreaker.state, CircuitState.open);
      expect(circuitBreaker.isOpen, isTrue);
      expect(circuitBreaker.failureCount, 5);
    });

    test('should return error when circuit is open', () async {
      final operation = () async {
        throw Exception('Test error');
      };

      for (int i = 0; i < 5; i++) {
        await circuitBreaker.execute(operation);
      }

      final result = await circuitBreaker.execute(operation);

      expect(result.isSuccess, isFalse);
      expect(result.state, CircuitState.open);
    });

    test('should succeed when operation succeeds', () async {
      final operation = () async => 'Success';

      final result = await circuitBreaker.execute(operation);

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Success');
      expect(result.state, CircuitState.closed);
    });

    test('should return data when successful', () async {
      final operation = () async => 42;

      final result = await circuitBreaker.execute(operation);

      expect(result.isSuccess, isTrue);
      expect(result.data, 42);
    });

    test('should reset failure count on success', () async {
      final failingOperation = () async {
        throw Exception('Test error');
      };
      final successOperation = () async => 'Success';

      for (int i = 0; i < 3; i++) {
        await circuitBreaker.execute(failingOperation);
      }

      await circuitBreaker.execute(successOperation);
      await circuitBreaker.execute(failingOperation);
      await circuitBreaker.execute(failingOperation);

      expect(circuitBreaker.failureCount, 2);
    });

    test('should reset manually', () async {
      final operation = () async => throw Exception('Test error');

      for (int i = 0; i < 5; i++) {
        await circuitBreaker.execute(operation);
      }

      expect(circuitBreaker.isOpen, isTrue);

      circuitBreaker.reset();

      expect(circuitBreaker.state, CircuitState.closed);
      expect(circuitBreaker.failureCount, 0);
    });

    test('should handle different return types', () async {
      final stringOp = () async => 'test';
      final intOp = () async => 123;
      final listOp = () async => [1, 2, 3];

      final stringResult = await circuitBreaker.execute(stringOp);
      final intResult = await circuitBreaker.execute(intOp);
      final listResult = await circuitBreaker.execute(listOp);

      expect(stringResult.data, 'test');
      expect(intResult.data, 123);
      expect(listResult.data, [1, 2, 3]);
    });

    test('should record errors correctly', () async {
      final operation = () async => throw Exception('Known error');

      final result = await circuitBreaker.execute(operation);

      expect(result.error, isNotNull);
      expect(result.error.toString(), contains('Known error'));
    });
  });

  group('CircuitBreakerRegistry', () {
    test('should return same instance for same name', () {
      final breaker1 = CircuitBreakerRegistry.getBreaker('test');
      final breaker2 = CircuitBreakerRegistry.getBreaker('test');

      expect(breaker1, same(breaker2));
    });

    test('should return different instances for different names', () {
      final breaker1 = CircuitBreakerRegistry.getBreaker('service1');
      final breaker2 = CircuitBreakerRegistry.getBreaker('service2');

      expect(breaker1, isNot(same(breaker2)));
    });

    test('should reset all breakers', () async {
      final breaker1 = CircuitBreakerRegistry.getBreaker('resetAll1');
      final breaker2 = CircuitBreakerRegistry.getBreaker('resetAll2');

      for (int i = 0; i < 5; i++) {
        await breaker1.execute(() async => throw Exception());
        await breaker2.execute(() async => throw Exception());
      }

      expect(breaker1.isOpen, isTrue);
      expect(breaker2.isOpen, isTrue);

      CircuitBreakerRegistry.resetAll();

      expect(breaker1.isClosed, isTrue);
      expect(breaker2.isClosed, isTrue);
    });

    test('should reset specific breaker', () async {
      final breaker1 = CircuitBreakerRegistry.getBreaker('resetSpecific1');
      final breaker2 = CircuitBreakerRegistry.getBreaker('resetSpecific2');

      for (int i = 0; i < 5; i++) {
        await breaker1.execute(() async => throw Exception());
        await breaker2.execute(() async => throw Exception());
      }

      CircuitBreakerRegistry.reset('resetSpecific1');

      expect(breaker1.isClosed, isTrue);
      expect(breaker2.isOpen, isTrue);
    });
  });

  group('CircuitBreakerResult', () {
    test('should create success result with data', () {
      final result = CircuitBreakerResult<int>(
        data: 42,
        isSuccess: true,
        state: CircuitState.closed,
      );

      expect(result.data, 42);
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.state, CircuitState.closed);
    });

    test('should create failure result with error', () {
      final error = Exception('Test error');
      final result = CircuitBreakerResult<int>(
        error: error,
        isSuccess: false,
        state: CircuitState.open,
      );

      expect(result.data, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.error, error);
      expect(result.state, CircuitState.open);
    });
  });
}
