import 'package:hive_flutter/hive_flutter.dart';

class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String key;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.key,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeToExpire => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() {
    if (data is Map) {
      return {
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'key': key,
      };
    }
    return {
      'data': data.toString(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'key': key,
    };
  }
}

class CacheConfig {
  final Duration defaultTtl;
  final int maxEntries;
  final bool persistToDisk;

  const CacheConfig({
    this.defaultTtl = const Duration(hours: 1),
    this.maxEntries = 100,
    this.persistToDisk = true,
  });
}

class ApiCacheService {
  static ApiCacheService? _instance;
  static ApiCacheService get instance => _instance ??= ApiCacheService._();

  ApiCacheService._();

  final Map<String, CacheEntry> _memoryCache = {};
  Box? _diskCache;
  CacheConfig _config = const CacheConfig();
  bool _isInitialized = false;

  Future<void> initialize({CacheConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) _config = config;

    if (_config.persistToDisk) {
      _diskCache = await Hive.openBox('api_cache');
      await _loadFromDisk();
    }

    _isInitialized = true;
  }

  Future<void> _loadFromDisk() async {
    if (_diskCache == null) return;

    final keys = _diskCache!.keys.toList();
    for (final key in keys) {
      try {
        final json = _diskCache!.get(key);
        if (json != null) {
          final entry = _parseEntry(json as Map);
          if (!entry.isExpired) {
            _memoryCache[key as String] = entry;
          } else {
            await _diskCache!.delete(key);
          }
        }
      } catch (e) {
        await _diskCache!.delete(key);
      }
    }
  }

  CacheEntry _parseEntry(Map json) {
    return CacheEntry(
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      key: json['key'],
    );
  }

  Future<T?> get<T>(String key) async {
    if (!_isInitialized) return null;

    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        return entry.data as T;
      }
      await remove(key);
    }
    return null;
  }

  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    if (!_isInitialized) return;

    if (_memoryCache.length >= _config.maxEntries) {
      await _evictOldest();
    }

    final now = DateTime.now();
    final duration = ttl ?? _config.defaultTtl;

    final entry = CacheEntry(
      data: data,
      createdAt: now,
      expiresAt: now.add(duration),
      key: key,
    );

    _memoryCache[key] = entry;

    if (_config.persistToDisk && _diskCache != null) {
      await _diskCache!.put(key, entry.toJson());
    }
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_diskCache != null) {
      await _diskCache!.delete(key);
    }
  }

  Future<void> _evictOldest() async {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestTime = entry.value.createdAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      await remove(oldestKey);
    }
  }

  Future<void> clear() async {
    _memoryCache.clear();
    if (_diskCache != null) {
      await _diskCache!.clear();
    }
  }

  Future<void> clearExpired() async {
    final expiredKeys = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  int get size => _memoryCache.length;

  bool hasKey(String key) {
    if (!_memoryCache.containsKey(key)) return false;
    return !_memoryCache[key]!.isExpired;
  }

  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final cached = await get<T>(key);
    if (cached != null) return cached;

    final data = await fetcher();
    await set(key, data, ttl: ttl);
    return data;
  }

  List<String> getKeys() => _memoryCache.keys.toList();

  Map<String, Duration> getCacheStats() {
    final stats = <String, Duration>{};
    for (final entry in _memoryCache.entries) {
      stats[entry.key] = entry.value.timeToExpire;
    }
    return stats;
  }

  void dispose() {
    _memoryCache.clear();
    _diskCache?.close();
    _isInitialized = false;
  }
}
