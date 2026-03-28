import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final String id;
  final LogLevel level;
  final String message;
  final String? source;
  final Object? error;
  final String? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.id,
    required this.level,
    required this.message,
    this.source,
    this.error,
    this.stackTrace,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'level': level.name,
    'message': message,
    'source': source,
    'error': error?.toString(),
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  String get levelEmoji {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();
  LoggingService._();

  Box<LogEntry>? _logBox;
  final List<void Function(LogEntry)> _listeners = [];
  bool _isInitialized = false;
  bool _enableConsoleLogging = kDebugMode;
  bool _enableFileLogging = true;
  int _maxLogEntries = 1000;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _logBox = await Hive.openBox<LogEntry>('logs');
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('LoggingService initialized');
      }
    } catch (e) {
      debugPrint('Failed to initialize LoggingService: $e');
    }
  }

  void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  void debug(String message, {String? source, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, source: source, metadata: metadata);
  }

  void info(String message, {String? source, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, source: source, metadata: metadata);
  }

  void warning(
    String message, {
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.warning, message, source: source, metadata: metadata);
  }

  void error(
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.error,
      message,
      source: source,
      error: error,
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
    );
  }

  void critical(
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.critical,
      message,
      source: source,
      error: error,
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    String? source,
    Object? error,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_generateId()}',
      level: level,
      message: message,
      source: source,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    if (_enableFileLogging && _isInitialized) {
      _logToFile(entry);
    }

    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (e) {
        debugPrint('Error in log listener: $e');
      }
    }
  }

  void _logToConsole(LogEntry entry) {
    final prefix = '${entry.levelEmoji} [${entry.source ?? 'App'}]';
    final logMessage = '$prefix ${entry.message}';

    switch (entry.level) {
      case LogLevel.debug:
        debugPrint(logMessage);
        break;
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint(logMessage);
        break;
      case LogLevel.error:
        debugPrint(logMessage);
        if (entry.error != null) {
          debugPrint('Error: ${entry.error}');
        }
        break;
      case LogLevel.critical:
        debugPrint(logMessage);
        if (entry.error != null) {
          debugPrint('Critical Error: ${entry.error}');
        }
        if (entry.stackTrace != null) {
          debugPrint('StackTrace: ${entry.stackTrace}');
        }
        break;
    }
  }

  Future<void> _logToFile(LogEntry entry) async {
    try {
      if (_logBox != null) {
        await _logBox!.put(entry.id, entry);

        if (_logBox!.length > _maxLogEntries) {
          await _cleanupOldLogs();
        }
      }
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  Future<void> _cleanupOldLogs() async {
    if (_logBox == null) return;

    final entries = _logBox!.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final toDelete = entries.take(_logBox!.length - _maxLogEntries ~/ 2);
    for (final entry in toDelete) {
      await _logBox!.delete(entry.id);
    }
  }

  List<LogEntry> getLogs({LogLevel? minLevel, int? limit}) {
    if (_logBox == null) return [];

    var logs = _logBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (minLevel != null) {
      logs = logs.where((log) => log.level.index >= minLevel.index).toList();
    }

    if (limit != null && limit > 0) {
      logs = logs.take(limit).toList();
    }

    return logs;
  }

  List<LogEntry> getErrorLogs() {
    return getLogs(minLevel: LogLevel.error);
  }

  Future<void> clearLogs() async {
    await _logBox?.clear();
  }

  Future<String> exportLogs() async {
    final logs = getLogs();
    final buffer = StringBuffer();

    buffer.writeln('=== CoDeXSdY Logs ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('');

    for (final log in logs) {
      buffer.writeln(
        '[${log.timestamp}] ${log.level.name.toUpperCase()} [${log.source ?? 'App'}]: ${log.message}',
      );
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  StackTrace: ${log.stackTrace}');
      }
    }

    return buffer.toString();
  }

  int _generateId() {
    return DateTime.now().microsecondsSinceEpoch % 100000;
  }

  void setEnableConsoleLogging(bool enable) {
    _enableConsoleLogging = enable;
  }

  void setEnableFileLogging(bool enable) {
    _enableFileLogging = enable;
  }

  void setMaxLogEntries(int max) {
    _maxLogEntries = max;
  }

  void logException(
    Object exception, {
    StackTrace? stackTrace,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    error(
      'Exception caught: $exception',
      source: source,
      error: exception,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }
}
