enum CircuitState { closed, open, halfOpen }

class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration openDuration;
  final int successThreshold;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 30),
    this.successThreshold = 3,
  });
}

class CircuitBreakerResult<T> {
  final T? data;
  final Object? error;
  final bool isSuccess;
  final CircuitState state;

  CircuitBreakerResult({
    this.data,
    this.error,
    required this.isSuccess,
    required this.state,
  });
}

class CircuitBreaker {
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  final CircuitBreakerConfig config;

  CircuitBreaker({this.config = const CircuitBreakerConfig()});

  CircuitState get state => _state;

  bool get isClosed => _state == CircuitState.closed;
  bool get isOpen => _state == CircuitState.open;
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  Future<CircuitBreakerResult<T>> execute<T>(
    Future<T> Function() operation,
  ) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
        _successCount = 0;
      } else {
        return CircuitBreakerResult(
          error: Exception('Circuit breaker is OPEN'),
          isSuccess: false,
          state: _state,
        );
      }
    }

    try {
      final result = await operation();

      _onSuccess();

      return CircuitBreakerResult(data: result, isSuccess: true, state: _state);
    } catch (e) {
      _onFailure();

      return CircuitBreakerResult(error: e, isSuccess: false, state: _state);
    }
  }

  void _onSuccess() {
    _failureCount = 0;

    if (_state == CircuitState.halfOpen) {
      _successCount++;
      if (_successCount >= config.successThreshold) {
        _state = CircuitState.closed;
      }
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _state = CircuitState.open;
    } else if (_failureCount >= config.failureThreshold) {
      _state = CircuitState.open;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return true;
    return DateTime.now().difference(_lastFailureTime!) >= config.openDuration;
  }

  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
  }

  int get failureCount => _failureCount;
  int get successCount => _successCount;
}

class CircuitBreakerRegistry {
  static final Map<String, CircuitBreaker> _breakers = {};

  static CircuitBreaker getBreaker(
    String name, {
    CircuitBreakerConfig? config,
  }) {
    if (!_breakers.containsKey(name)) {
      _breakers[name] = CircuitBreaker(
        config: config ?? const CircuitBreakerConfig(),
      );
    }
    return _breakers[name]!;
  }

  static void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }

  static void reset(String name) {
    _breakers[name]?.reset();
  }
}
