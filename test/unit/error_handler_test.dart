import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/error_handler.dart';

void main() {
  group('AppError', () {
    test('should create error with default values', () {
      final error = AppError(message: 'Test error');

      expect(error.message, 'Test error');
      expect(error.severity, ErrorSeverity.medium);
      expect(error.timestamp, isNotNull);
      expect(error.context, isNull);
    });

    test('should create error with custom severity', () {
      final error = AppError(
        message: 'Critical error',
        severity: ErrorSeverity.critical,
      );

      expect(error.severity, ErrorSeverity.critical);
    });

    test('should include context when provided', () {
      final error = AppError(message: 'Test', context: 'HomePage.build');

      expect(error.context, 'HomePage.build');
    });
  });

  group('ErrorHandlerConfig', () {
    test('should have sensible defaults', () {
      const config = ErrorHandlerConfig();

      expect(config.logToConsole, isTrue);
      expect(config.logToFile, isTrue);
      expect(config.showUserNotification, isTrue);
      expect(config.minimumSeverityForNotification, ErrorSeverity.high);
    });

    test('should create copy with modifications', () {
      const original = ErrorHandlerConfig();
      final modified = original.copyWith(
        logToConsole: false,
        minimumSeverityForNotification: ErrorSeverity.critical,
      );

      expect(modified.logToConsole, isFalse);
      expect(modified.minimumSeverityForNotification, ErrorSeverity.critical);
      expect(original.logToConsole, isTrue);
    });
  });

  group('GlobalErrorHandler', () {
    late GlobalErrorHandler handler;

    setUp(() {
      handler = GlobalErrorHandler.instance;
      handler.clearErrorLog();
    });

    test('should configure handler', () {
      const config = ErrorHandlerConfig(logToConsole: false);
      handler.configure(config);

      expect(handler.errorLog, isEmpty);
    });

    test('should handle error and add to log', () async {
      await handler.handleError(
        'Test error message',
        error: Exception('Test'),
        severity: ErrorSeverity.high,
      );

      expect(handler.errorLog.length, 1);
      expect(handler.errorLog.first.message, 'Test error message');
      expect(handler.errorLog.first.severity, ErrorSeverity.high);
    });

    test('should clear error log', () async {
      await handler.handleError('Error 1');
      await handler.handleError('Error 2');

      expect(handler.errorLog.length, 2);

      handler.clearErrorLog();

      expect(handler.errorLog.length, 0);
    });

    test('should get errors by severity', () async {
      await handler.handleError('Low error', severity: ErrorSeverity.low);
      await handler.handleError('High error', severity: ErrorSeverity.high);
      await handler.handleError(
        'Critical error',
        severity: ErrorSeverity.critical,
      );

      final highErrors = handler.getErrorsBySeverity(ErrorSeverity.high);
      expect(highErrors.length, 1);
      expect(highErrors.first.message, 'High error');
    });

    test('should get recent errors', () async {
      for (int i = 0; i < 15; i++) {
        await handler.handleError('Error $i');
      }

      final recent = handler.getRecentErrors(count: 5);
      expect(recent.length, 5);
      expect(recent.first.message, 'Error 14');
    });

    test('should listen to error stream', () async {
      final errors = <AppError>[];
      final subscription = handler.errorStream.listen(errors.add);

      await handler.handleError('Stream test error');

      expect(errors.length, 1);
      expect(errors.first.message, 'Stream test error');

      await subscription.cancel();
    });

    test('should register and call recovery handler', () async {
      bool recoveryCalled = false;

      handler.registerRecoveryHandler(ErrorSeverity.critical, (error) async {
        recoveryCalled = true;
      });

      await handler.handleError(
        'Critical error',
        severity: ErrorSeverity.critical,
        tryRecovery: true,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(recoveryCalled, isTrue);
    });

    test('should limit error log to 1000 entries', () async {
      for (int i = 0; i < 1100; i++) {
        await handler.handleError('Error $i');
      }

      expect(handler.errorLog.length, lessThanOrEqualTo(1000));
    });
  });

  group('ErrorSeverity', () {
    test('should have correct order', () {
      expect(ErrorSeverity.low.index, 0);
      expect(ErrorSeverity.medium.index, 1);
      expect(ErrorSeverity.high.index, 2);
      expect(ErrorSeverity.critical.index, 3);
    });
  });
}
