import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.message,
    this.error,
    this.stackTrace,
    this.severity = ErrorSeverity.medium,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AppError: $message (severity: $severity)';
}

class ErrorHandlerConfig {
  final bool logToConsole;
  final bool logToFile;
  final bool showUserNotification;
  final bool sendToAnalytics;
  final ErrorSeverity minimumSeverityForNotification;

  const ErrorHandlerConfig({
    this.logToConsole = true,
    this.logToFile = true,
    this.showUserNotification = true,
    this.sendToAnalytics = false,
    this.minimumSeverityForNotification = ErrorSeverity.high,
  });

  ErrorHandlerConfig copyWith({
    bool? logToConsole,
    bool? logToFile,
    bool? showUserNotification,
    bool? sendToAnalytics,
    ErrorSeverity? minimumSeverityForNotification,
  }) {
    return ErrorHandlerConfig(
      logToConsole: logToConsole ?? this.logToConsole,
      logToFile: logToFile ?? this.logToFile,
      showUserNotification: showUserNotification ?? this.showUserNotification,
      sendToAnalytics: sendToAnalytics ?? this.sendToAnalytics,
      minimumSeverityForNotification:
          minimumSeverityForNotification ?? this.minimumSeverityForNotification,
    );
  }
}

typedef ErrorRecoveryCallback = Future<void> Function(AppError error);

class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance =>
      _instance ??= GlobalErrorHandler._();

  GlobalErrorHandler._();

  ErrorHandlerConfig _config = const ErrorHandlerConfig();
  final List<AppError> _errorLog = [];
  final Map<ErrorSeverity, ErrorRecoveryCallback> _recoveryHandlers = {};
  bool _isInitialized = false;

  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorController.stream;

  List<AppError> get errorLog => List.unmodifiable(_errorLog);

  void configure(ErrorHandlerConfig config) {
    _config = config;
  }

  void registerRecoveryHandler(
    ErrorSeverity severity,
    ErrorRecoveryCallback handler,
  ) {
    _recoveryHandlers[severity] = handler;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
        context: details.context?.toString(),
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      handleError(
        'Platform Error',
        error: error,
        stackTrace: stackTrace,
        context: 'PlatformDispatcher',
      );
      return true;
    };

    _isInitialized = true;
    _log('GlobalErrorHandler initialized');
  }

  Future<void> handleError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool tryRecovery = true,
  }) async {
    final appError = AppError(
      message: message,
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
    );

    _errorLog.add(appError);

    if (_errorLog.length > 1000) {
      _errorLog.removeAt(0);
    }

    if (_config.logToConsole) {
      _logError(appError);
    }

    _errorController.add(appError);

    if (severity.index >= _config.minimumSeverityForNotification.index) {
      await _attemptRecovery(appError);
    }
  }

  Future<void> _attemptRecovery(AppError error) async {
    final handler = _recoveryHandlers[error.severity];
    if (handler != null) {
      try {
        await handler(error);
      } catch (e) {
        _log('Recovery handler failed: $e');
      }
    }
  }

  void _logError(AppError error) {
    final prefix = _severityPrefix(error.severity);
    debugPrint('$prefix ${error.timestamp}: ${error.message}');
    if (error.context != null) {
      debugPrint('  Context: ${error.context}');
    }
    if (error.error != null) {
      debugPrint('  Error: ${error.error}');
    }
    if (error.stackTrace != null) {
      debugPrint('  Stack: ${error.stackTrace}');
    }
  }

  String _severityPrefix(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return '🔵';
      case ErrorSeverity.medium:
        return '🟡';
      case ErrorSeverity.high:
        return '🟠';
      case ErrorSeverity.critical:
        return '🔴';
    }
  }

  void _log(String message) {
    if (_config.logToConsole) {
      debugPrint('[ErrorHandler] $message');
    }
  }

  void clearErrorLog() {
    _errorLog.clear();
  }

  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorLog.where((e) => e.severity == severity).toList();
  }

  List<AppError> getRecentErrors({int count = 10}) {
    return _errorLog.reversed.take(count).toList();
  }

  void dispose() {
    _errorController.close();
    _isInitialized = false;
  }
}

class RecoveryStrategies {
  static Future<void> retryOperation(AppError error) async {
    GlobalErrorHandler.instance._log('Attempting retry for: ${error.message}');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Future<void> showErrorDialog(AppError error) async {
    GlobalErrorHandler.instance._log('Showing error dialog: ${error.message}');
  }

  static Future<void> saveErrorReport(AppError error) async {
    GlobalErrorHandler.instance._log('Saving error report: ${error.message}');
  }
}
