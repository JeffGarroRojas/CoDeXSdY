import 'dart:async';

enum RetryStrategy { exponential, linear, constant }

class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final RetryStrategy strategy;
  final double backoffMultiplier;
  final List<int> retryableStatusCodes;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.strategy = RetryStrategy.exponential,
    this.backoffMultiplier = 2.0,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  RetryConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    RetryStrategy? strategy,
    double? backoffMultiplier,
    List<int>? retryableStatusCodes,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      strategy: strategy ?? this.strategy,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      retryableStatusCodes: retryableStatusCodes ?? this.retryableStatusCodes,
    );
  }
}

class RetryResult<T> {
  final T? data;
  final Object? error;
  final bool isSuccess;
  final int attempts;
  final Duration totalDuration;

  RetryResult({
    this.data,
    this.error,
    required this.isSuccess,
    required this.attempts,
    required this.totalDuration,
  });
}

class RetryService {
  static RetryConfig defaultConfig = const RetryConfig();

  static Future<RetryResult<T>> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    final stopwatch = Stopwatch()..start();
    Object? lastError;
    int attempts = 0;

    while (attempts < config.maxAttempts) {
      attempts++;

      try {
        final result = await operation();
        stopwatch.stop();

        return RetryResult(
          data: result,
          isSuccess: true,
          attempts: attempts,
          totalDuration: stopwatch.elapsed,
        );
      } catch (e) {
        lastError = e;

        final shouldRetryNow = shouldRetry?.call(e) ?? _isRetryable(e, config);

        if (!shouldRetryNow || attempts >= config.maxAttempts) {
          stopwatch.stop();

          return RetryResult(
            error: e,
            isSuccess: false,
            attempts: attempts,
            totalDuration: stopwatch.elapsed,
          );
        }

        onRetry?.call(attempts, e);

        final delay = _calculateDelay(attempts, config);
        await Future.delayed(delay);
      }
    }

    stopwatch.stop();
    return RetryResult(
      error: lastError,
      isSuccess: false,
      attempts: attempts,
      totalDuration: stopwatch.elapsed,
    );
  }

  static bool _isRetryable(Object error, RetryConfig config) {
    if (error is Exception) {
      final message = error.toString().toLowerCase();

      if (message.contains('timeout') ||
          message.contains('network') ||
          message.contains('connection') ||
          message.contains('socket') ||
          message.contains('temporary') ||
          message.contains('retry') ||
          message.contains('error')) {
        return true;
      }
    }
    return false;
  }

  static Duration _calculateDelay(int attempt, RetryConfig config) {
    Duration delay;

    switch (config.strategy) {
      case RetryStrategy.exponential:
        final exponentialDelay =
            config.initialDelay.inMilliseconds *
            (config.backoffMultiplier * (attempt - 1));
        delay = Duration(milliseconds: exponentialDelay.toInt());
        break;

      case RetryStrategy.linear:
        delay = Duration(
          milliseconds: config.initialDelay.inMilliseconds * attempt,
        );
        break;

      case RetryStrategy.constant:
        delay = config.initialDelay;
        break;
    }

    if (delay > config.maxDelay) {
      delay = config.maxDelay;
    }

    final jitter = Duration(
      milliseconds: (delay.inMilliseconds * 0.1 * (attempt % 3 - 1))
          .toInt()
          .abs(),
    );

    return delay + jitter;
  }

  static RetryConfig forQuickRetries() {
    return const RetryConfig(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 200),
      maxDelay: Duration(seconds: 2),
      strategy: RetryStrategy.exponential,
      backoffMultiplier: 1.5,
    );
  }

  static RetryConfig forNetworkCalls() {
    return const RetryConfig(
      maxAttempts: 5,
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 30),
      strategy: RetryStrategy.exponential,
      backoffMultiplier: 2.0,
    );
  }
}
