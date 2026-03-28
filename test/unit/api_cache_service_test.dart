import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/api_cache_service.dart';

void main() {
  group('CacheEntry', () {
    test('should create cache entry', () {
      final entry = CacheEntry(
        data: 'test data',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        key: 'test_key',
      );

      expect(entry.data, 'test data');
      expect(entry.key, 'test_key');
      expect(entry.isExpired, isFalse);
    });

    test('should detect expired entry', () {
      final entry = CacheEntry(
        data: 'expired data',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        key: 'expired_key',
      );

      expect(entry.isExpired, isTrue);
    });

    test('should calculate time to expire', () {
      final entry = CacheEntry(
        data: 'test',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        key: 'test_key',
      );

      expect(entry.timeToExpire.inMinutes, greaterThan(0));
      expect(entry.timeToExpire.inMinutes, lessThanOrEqualTo(30));
    });
  });

  group('CacheConfig', () {
    test('should have sensible defaults', () {
      const config = CacheConfig();

      expect(config.defaultTtl, const Duration(hours: 1));
      expect(config.maxEntries, 100);
      expect(config.persistToDisk, isTrue);
    });
  });

  group('ApiCacheService', () {
    late ApiCacheService cache;

    setUp(() async {
      cache = ApiCacheService.instance;
      await cache.initialize(
        config: const CacheConfig(
          defaultTtl: Duration(hours: 1),
          maxEntries: 50,
          persistToDisk: false,
        ),
      );
    });

    tearDown(() {
      cache.clear();
    });

    test('should store and retrieve data', () async {
      await cache.set('key1', 'value1');
      final result = await cache.get<String>('key1');

      expect(result, 'value1');
    });

    test('should return null for non-existent key', () async {
      final result = await cache.get<String>('non_existent');

      expect(result, isNull);
    });

    test('should check if key exists', () async {
      await cache.set('existing_key', 'value');

      expect(cache.hasKey('existing_key'), isTrue);
      expect(cache.hasKey('non_existent'), isFalse);
    });

    test('should remove entry', () async {
      await cache.set('to_remove', 'value');
      expect(cache.hasKey('to_remove'), isTrue);

      await cache.remove('to_remove');
      expect(cache.hasKey('to_remove'), isFalse);
    });

    test('should clear all entries', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      expect(cache.size, 2);

      await cache.clear();
      expect(cache.size, 0);
    });

    test('should respect custom TTL', () async {
      await cache.set(
        'short_lived',
        'value',
        ttl: const Duration(milliseconds: 100),
      );

      expect(cache.hasKey('short_lived'), isTrue);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(cache.hasKey('short_lived'), isFalse);
    });

    test('should track cache size', () async {
      expect(cache.size, 0);

      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');

      expect(cache.size, 2);
    });

    test('should get all keys', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      final keys = cache.getKeys();
      expect(keys.length, 3);
      expect(keys, containsAll(['key1', 'key2', 'key3']));
    });

    test('should get cache stats', () async {
      await cache.set('key1', 'value1');

      final stats = cache.getCacheStats();
      expect(stats.containsKey('key1'), isTrue);
      expect(stats['key1']!.inMinutes, greaterThan(0));
    });

    test('should handle concurrent operations', () async {
      await Future.wait([
        cache.set('async1', 'value1'),
        cache.set('async2', 'value2'),
        cache.set('async3', 'value3'),
      ]);

      expect(cache.size, 3);

      final results = await Future.wait([
        cache.get<String>('async1'),
        cache.get<String>('async2'),
        cache.get<String>('async3'),
      ]);

      expect(results, ['value1', 'value2', 'value3']);
    });

    test('should handle different data types', () async {
      await cache.set('int', 42);
      await cache.set('list', [1, 2, 3]);
      await cache.set('map', {'key': 'value'});

      expect(await cache.get<int>('int'), 42);
      expect(await cache.get<List>('list'), [1, 2, 3]);
      expect(await cache.get<Map>('map'), {'key': 'value'});
    });
  });
}
