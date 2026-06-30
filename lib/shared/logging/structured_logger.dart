import 'dart:async';
import 'dart:convert';

enum LogLevel { debug, info, warn, error }

class LogRecord {
  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.fields,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final Map<String, Object?> fields;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() => {
        'ts': timestamp.toIso8601String(),
        'level': level.name,
        'tag': tag,
        ...fields,
        if (error != null) 'error': error.toString(),
      };
}

/// Structured-logging abstraction. Implementations decide where records go.
/// The orchestrators only know this interface.
abstract interface class StructuredLogger {
  void debug(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace});
  void info(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace});
  void warn(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace});
  void error(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace});
  Stream<LogRecord> get records;
}

class _BaseStructuredLogger implements StructuredLogger {
  final StreamController<LogRecord> _controller =
      StreamController<LogRecord>.broadcast();

  @override
  Stream<LogRecord> get records => _controller.stream;

  void emit(LogRecord r) {
    if (!_controller.isClosed) _controller.add(r);
  }

  @override
  void debug(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace}) {
    emit(LogRecord(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        tag: tag,
        fields: fields,
        error: error,
        stackTrace: stackTrace));
  }

  @override
  void info(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace}) {
    emit(LogRecord(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        tag: tag,
        fields: fields,
        error: error,
        stackTrace: stackTrace));
  }

  @override
  void warn(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace}) {
    emit(LogRecord(
        timestamp: DateTime.now(),
        level: LogLevel.warn,
        tag: tag,
        fields: fields,
        error: error,
        stackTrace: stackTrace));
  }

  @override
  void error(String tag, Map<String, Object?> fields,
      {Object? error, StackTrace? stackTrace}) {
    emit(LogRecord(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        tag: tag,
        fields: fields,
        error: error,
        stackTrace: stackTrace));
  }
}

/// Default sink: structured JSON to stdout. Suitable for development and CI.
class ConsoleStructuredLogger extends _BaseStructuredLogger {
  ConsoleStructuredLogger({this.minLevel = LogLevel.debug}) {
    records.listen(_print);
  }
  final LogLevel minLevel;

  void _print(LogRecord r) {
    if (r.level.index < minLevel.index) return;
    // ignore: avoid_print
    print(jsonEncode(r.toJson()));
    if (r.stackTrace != null) {
      // ignore: avoid_print
      print(r.stackTrace);
    }
  }
}
