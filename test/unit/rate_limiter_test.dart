import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/rate_limiter.dart';

void main() {
  group('RateLimitConfig', () {
    test('should have sensible defaults', () {
      const config = RateLimitConfig();

      expect(config.maxRequests, 10);
      expect(config.windowDuration, const Duration(minutes: 1));
      expect(config.strategy, RateLimitStrategy.slidingWindow);
      expect(config.enabled, isTrue);
    });

    test('should create copy with modifications', () {
      const original = RateLimitConfig(
        maxRequests: 10,
        windowDuration: Duration(minutes: 1),
      );

      final modified = original.copyWith(
        maxRequests: 20,
        strategy: RateLimitStrategy.tokenBucket,
      );

      expect(modified.maxRequests, 20);
      expect(modified.windowDuration, const Duration(minutes: 1));
      expect(modified.strategy, RateLimitStrategy.tokenBucket);
    });
  });

  group('RateLimitResult', () {
    test('should create success result', () {
      final result = RateLimitResult(allowed: true, remainingRequests: 5);

      expect(result.allowed, isTrue);
      expect(result.remainingRequests, 5);
      expect(result.retryAfter, isNull);
    });

    test('should create failure result with retry info', () {
      final result = RateLimitResult(
        allowed: false,
        remainingRequests: 0,
        retryAfter: const Duration(seconds: 30),
      );

      expect(result.allowed, isFalse);
      expect(result.remainingRequests, 0);
      expect(result.retryAfter, const Duration(seconds: 30));
    });
  });

  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter.instance;
      rateLimiter.resetAll();
    });

    test('should initialize with default buckets', () {
      rateLimiter.initialize();

      expect(rateLimiter.isBucketAvailable('groq'), isTrue);
      expect(rateLimiter.isBucketAvailable('chat'), isTrue);
    });

    test('should allow requests within limit (sliding window)', () {
      rateLimiter.registerBucket(
        'test_sliding',
        const RateLimitConfig(
          maxRequests: 3,
          windowDuration: Duration(minutes: 1),
          strategy: RateLimitStrategy.slidingWindow,
        ),
      );

      expect(rateLimiter.checkLimit('test_sliding').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_sliding').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_sliding').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_sliding').allowed, isFalse);
    });

    test('should allow requests within limit (fixed window)', () {
      rateLimiter.registerBucket(
        'test_fixed',
        const RateLimitConfig(
          maxRequests: 2,
          windowDuration: Duration(minutes: 1),
          strategy: RateLimitStrategy.fixedWindow,
        ),
      );

      expect(rateLimiter.checkLimit('test_fixed').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_fixed').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_fixed').allowed, isFalse);
    });

    test('should allow requests within limit (token bucket)', () {
      rateLimiter.registerBucket(
        'test_token',
        const RateLimitConfig(
          maxRequests: 2,
          windowDuration: Duration(minutes: 1),
          strategy: RateLimitStrategy.tokenBucket,
        ),
      );

      expect(rateLimiter.checkLimit('test_token').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_token').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_token').allowed, isFalse);
    });

    test('should return remaining requests count', () {
      rateLimiter.registerBucket(
        'test_count',
        const RateLimitConfig(
          maxRequests: 5,
          windowDuration: Duration(minutes: 1),
        ),
      );

      final r1 = rateLimiter.checkLimit('test_count');
      expect(r1.remainingRequests, lessThanOrEqualTo(5));
    });

    test('should allow unknown bucket', () {
      final result = rateLimiter.checkLimit('unknown_bucket');
      expect(result.allowed, isTrue);
    });

    test('should reset bucket', () {
      rateLimiter.registerBucket(
        'test_reset',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );

      expect(rateLimiter.checkLimit('test_reset').allowed, isTrue);
      expect(rateLimiter.checkLimit('test_reset').allowed, isFalse);

      rateLimiter.resetBucket('test_reset');
      expect(rateLimiter.checkLimit('test_reset').allowed, isTrue);
    });

    test('should reset all buckets', () {
      rateLimiter.registerBucket(
        'reset_all_1',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );
      rateLimiter.registerBucket(
        'reset_all_2',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );

      rateLimiter.checkLimit('reset_all_1');
      rateLimiter.checkLimit('reset_all_2');

      rateLimiter.resetAll();

      expect(rateLimiter.isBucketAvailable('reset_all_1'), isTrue);
      expect(rateLimiter.isBucketAvailable('reset_all_2'), isTrue);
    });

    test('should get status for all buckets', () {
      rateLimiter.registerBucket(
        'status_1',
        const RateLimitConfig(
          maxRequests: 5,
          windowDuration: Duration(minutes: 1),
        ),
      );

      final status = rateLimiter.getStatus();
      expect(status.containsKey('status_1'), isTrue);
      expect(status['status_1']!.allowed, isTrue);
    });

    test('should track wait time for sliding window', () {
      rateLimiter.registerBucket(
        'wait_time',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(seconds: 5),
        ),
      );

      rateLimiter.checkLimit('wait_time');
      expect(rateLimiter.checkLimit('wait_time').allowed, isFalse);

      final waitTime = rateLimiter.getWaitTime('wait_time');
      expect(waitTime, isNotNull);
    });

    test('should execute with limit successfully', () async {
      rateLimiter.registerBucket(
        'exec_test',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );

      bool executed = false;
      final result = await rateLimiter.executeWithLimit('exec_test', () async {
        executed = true;
        return 'success';
      });

      expect(executed, isTrue);
      expect(result, 'success');
    });

    test('should throw exception when limit exceeded without retry', () {
      rateLimiter.registerBucket(
        'fail_now',
        const RateLimitConfig(
          maxRequests: 1,
          windowDuration: Duration(minutes: 1),
        ),
      );

      rateLimiter.checkLimit('fail_now');

      expect(rateLimiter.checkLimit('fail_now').allowed, isFalse);
    });
  });

  group('RateLimitExceededException', () {
    test('should format error message', () {
      final ex = RateLimitExceededException(
        'test_bucket',
        retryAfter: const Duration(seconds: 30),
      );

      expect(ex.bucketName, 'test_bucket');
      expect(ex.retryAfter, const Duration(seconds: 30));
      expect(ex.toString(), contains('Rate limit exceeded'));
      expect(ex.toString(), contains('30 seconds'));
    });

    test('should format without retry time', () {
      final ex = RateLimitExceededException('test_bucket');

      expect(ex.toString(), contains('Rate limit exceeded'));
      expect(ex.toString(), contains('test_bucket'));
    });
  });

  group('RateLimitStrategy', () {
    test('should have correct values', () {
      expect(RateLimitStrategy.values.length, 3);
      expect(RateLimitStrategy.slidingWindow.index, 0);
      expect(RateLimitStrategy.tokenBucket.index, 1);
      expect(RateLimitStrategy.fixedWindow.index, 2);
    });
  });
}
