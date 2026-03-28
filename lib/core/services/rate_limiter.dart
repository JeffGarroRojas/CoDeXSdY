import 'dart:async';
import 'package:flutter/foundation.dart';

enum RateLimitStrategy { slidingWindow, tokenBucket, fixedWindow }

class RateLimitConfig {
  final int maxRequests;
  final Duration windowDuration;
  final RateLimitStrategy strategy;
  final bool enabled;

  const RateLimitConfig({
    this.maxRequests = 10,
    this.windowDuration = const Duration(minutes: 1),
    this.strategy = RateLimitStrategy.slidingWindow,
    this.enabled = true,
  });

  RateLimitConfig copyWith({
    int? maxRequests,
    Duration? windowDuration,
    RateLimitStrategy? strategy,
    bool? enabled,
  }) {
    return RateLimitConfig(
      maxRequests: maxRequests ?? this.maxRequests,
      windowDuration: windowDuration ?? this.windowDuration,
      strategy: strategy ?? this.strategy,
      enabled: enabled ?? this.enabled,
    );
  }
}

class RateLimitResult {
  final bool allowed;
  final int remainingRequests;
  final Duration? retryAfter;
  final DateTime? nextAvailable;

  RateLimitResult({
    required this.allowed,
    required this.remainingRequests,
    this.retryAfter,
    this.nextAvailable,
  });
}

class RateLimiter {
  static RateLimiter? _instance;
  static RateLimiter get instance => _instance ??= RateLimiter._();

  RateLimiter._();

  final Map<String, _RateLimitBucket> _buckets = {};
  final Map<String, RateLimitConfig> _configs = {};
  bool _isInitialized = false;

  static const RateLimitConfig groqConfig = RateLimitConfig(
    maxRequests: 30,
    windowDuration: Duration(minutes: 1),
    strategy: RateLimitStrategy.slidingWindow,
  );

  static const RateLimitConfig fastConfig = RateLimitConfig(
    maxRequests: 60,
    windowDuration: Duration(minutes: 1),
    strategy: RateLimitStrategy.slidingWindow,
  );

  static const RateLimitConfig slowConfig = RateLimitConfig(
    maxRequests: 10,
    windowDuration: Duration(minutes: 1),
    strategy: RateLimitStrategy.slidingWindow,
  );

  void initialize() {
    if (_isInitialized) return;

    registerBucket('groq', groqConfig);
    registerBucket(
      'ai_generate',
      const RateLimitConfig(
        maxRequests: 5,
        windowDuration: Duration(minutes: 1),
      ),
    );
    registerBucket(
      'chat',
      const RateLimitConfig(
        maxRequests: 20,
        windowDuration: Duration(minutes: 1),
      ),
    );
    registerBucket(
      'flashcard_generate',
      const RateLimitConfig(
        maxRequests: 10,
        windowDuration: Duration(minutes: 1),
      ),
    );

    _isInitialized = true;
    debugPrint('[RateLimiter] Initialized with ${_buckets.length} buckets');
  }

  void registerBucket(String name, RateLimitConfig config) {
    _configs[name] = config;
    _buckets[name] = _RateLimitBucket(
      maxRequests: config.maxRequests,
      windowDuration: config.windowDuration,
      strategy: config.strategy,
    );
  }

  RateLimitResult checkLimit(String bucketName) {
    if (!_buckets.containsKey(bucketName)) {
      debugPrint('[RateLimiter] Unknown bucket: $bucketName, allowing request');
      return RateLimitResult(allowed: true, remainingRequests: -1);
    }

    final bucket = _buckets[bucketName]!;
    final config = _configs[bucketName]!;

    if (!config.enabled) {
      return RateLimitResult(
        allowed: true,
        remainingRequests: config.maxRequests,
      );
    }

    final allowed = bucket.tryConsume();

    if (!allowed) {
      debugPrint('[RateLimiter] Rate limit exceeded for bucket: $bucketName');
      return RateLimitResult(
        allowed: false,
        remainingRequests: 0,
        retryAfter: bucket.getWaitTime(),
      );
    }

    final currentCount = bucket.getCurrentCount();
    return RateLimitResult(
      allowed: true,
      remainingRequests: (config.maxRequests - currentCount).clamp(
        0,
        config.maxRequests,
      ),
    );
  }

  Future<T?> executeWithLimit<T>(
    String bucketName,
    Future<T> Function() operation,
  ) async {
    final result = checkLimit(bucketName);

    if (!result.allowed) {
      if (result.retryAfter != null) {
        await Future.delayed(result.retryAfter!);
        return executeWithLimit(bucketName, operation);
      }
      throw RateLimitExceededException(
        bucketName,
        retryAfter: result.retryAfter,
      );
    }

    return operation();
  }

  void resetBucket(String bucketName) {
    _buckets[bucketName]?.reset();
  }

  void resetAll() {
    for (final bucket in _buckets.values) {
      bucket.reset();
    }
  }

  Map<String, RateLimitResult> getStatus() {
    final status = <String, RateLimitResult>{};
    for (final entry in _buckets.entries) {
      status[entry.key] = entry.value.getStatus();
    }
    return status;
  }

  bool isBucketAvailable(String bucketName) {
    return checkLimit(bucketName).allowed;
  }

  Duration? getWaitTime(String bucketName) {
    if (!_buckets.containsKey(bucketName)) return null;
    return _buckets[bucketName]!.getWaitTime();
  }
}

class _RateLimitBucket {
  final int maxRequests;
  final Duration windowDuration;
  final RateLimitStrategy strategy;

  final List<DateTime> _requests = [];
  int _tokens;
  DateTime _lastRefill = DateTime.now();

  _RateLimitBucket({
    required this.maxRequests,
    required this.windowDuration,
    required this.strategy,
  }) : _tokens = maxRequests;

  bool tryConsume() {
    switch (strategy) {
      case RateLimitStrategy.slidingWindow:
        return _slidingWindowConsume();
      case RateLimitStrategy.tokenBucket:
        return _tokenBucketConsume();
      case RateLimitStrategy.fixedWindow:
        return _fixedWindowConsume();
    }
  }

  bool _slidingWindowConsume() {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    _requests.removeWhere((t) => t.isBefore(windowStart));

    if (_requests.length >= maxRequests) {
      return false;
    }

    _requests.add(now);
    return true;
  }

  bool _tokenBucketConsume() {
    _refillTokens();

    if (_tokens < 1) {
      return false;
    }

    _tokens--;
    return true;
  }

  void _refillTokens() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);

    if (elapsed >= windowDuration) {
      _tokens = maxRequests;
      _lastRefill = now;
    }
  }

  bool _fixedWindowConsume() {
    final now = DateTime.now();

    if (_requests.isEmpty ||
        now.difference(_requests.first) >= windowDuration) {
      _requests.clear();
      _requests.add(now);
      return true;
    }

    if (_requests.length >= maxRequests) {
      return false;
    }

    _requests.add(now);
    return true;
  }

  void reset() {
    _requests.clear();
    _tokens = maxRequests;
    _lastRefill = DateTime.now();
  }

  RateLimitResult getStatus() {
    int remaining;
    DateTime? nextAvailable;

    switch (strategy) {
      case RateLimitStrategy.slidingWindow:
        final now = DateTime.now();
        final windowStart = now.subtract(windowDuration);
        _requests.removeWhere((t) => t.isBefore(windowStart));
        remaining = maxRequests - _requests.length;
        if (remaining <= 0 && _requests.isNotEmpty) {
          nextAvailable = _requests.first.add(windowDuration);
        }
        break;
      case RateLimitStrategy.tokenBucket:
        _refillTokens();
        remaining = _tokens;
        break;
      case RateLimitStrategy.fixedWindow:
        remaining = maxRequests - _requests.length;
        break;
    }

    Duration? retryAfter;
    if (remaining <= 0) {
      retryAfter = windowDuration;
    }

    return RateLimitResult(
      allowed: remaining > 0,
      remainingRequests: remaining.clamp(0, maxRequests),
      retryAfter: retryAfter,
      nextAvailable: nextAvailable,
    );
  }

  Duration? getWaitTime() {
    if (strategy == RateLimitStrategy.slidingWindow && _requests.isNotEmpty) {
      final oldestInWindow = _requests.first;
      final nextAvailable = oldestInWindow.add(windowDuration);
      final waitTime = nextAvailable.difference(DateTime.now());

      if (waitTime.isNegative) return null;
      return waitTime;
    }
    return null;
  }

  int getCurrentCount() {
    if (strategy == RateLimitStrategy.slidingWindow) {
      final now = DateTime.now();
      final windowStart = now.subtract(windowDuration);
      _requests.removeWhere((t) => t.isBefore(windowStart));
      return _requests.length;
    }
    return maxRequests - _tokens;
  }
}

class RateLimitExceededException implements Exception {
  final String bucketName;
  final Duration? retryAfter;

  RateLimitExceededException(this.bucketName, {this.retryAfter});

  @override
  String toString() {
    if (retryAfter != null) {
      return 'Rate limit exceeded for $bucketName. Retry after ${retryAfter!.inSeconds} seconds.';
    }
    return 'Rate limit exceeded for $bucketName.';
  }
}
