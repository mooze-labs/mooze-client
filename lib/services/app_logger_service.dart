import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/services/log_config.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical;

  String get displayName => name.toUpperCase();
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String toFormattedString() {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final buffer = StringBuffer();
    buffer.writeln('[$timeStr] [${level.displayName}] [$tag] $message');

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('StackTrace:');
      buffer.writeln(stackTrace.toString());
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

class AppLoggerService {
  static final AppLoggerService _instance = AppLoggerService._internal();
  factory AppLoggerService() {
    debugPrint(
      '[AppLogger] factory() called - returning instance ${_instance.hashCode}',
    );
    debugPrint('[AppLogger] _database is null? ${_instance._database == null}');
    return _instance;
  }

  AppLoggerService._internal() {
    debugPrint('[AppLogger] Singleton instance created: ${hashCode}');
  }

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  AppDatabase? _database;

  LogConfig _config = LogConfig.production;

  Timer? _cleanupTimer;

  Stream<LogEntry> get logStream => _logStreamController.stream;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  static const int maxLogsInMemory = 1000;

  static const int maxLogFileSize = 5 * 1024 * 1024;

  Future<void> initialize(AppDatabase database, {LogConfig? config}) async {
    debugPrint('[AppLogger] initialize() called - Setting database...');
    debugPrint('[AppLogger] Database instance: ${database.hashCode}');

    _database = database;

    debugPrint(
      '[AppLogger] Database set. _database is null? ${_database == null}',
    );

    if (config != null) {
      _config = config;
    }

    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      cleanOldLogs();
    });

    await cleanOldLogs();

    debugPrint('[AppLogger] Initialization complete!');
    info('AppLogger', 'Logger initialized with database and config: $_config');
  }

  void updateConfig(LogConfig config) {
    _config = config;
    info('AppLogger', 'Logger config updated: $_config');
  }

  LogConfig get config => _config;

  void debug(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, tag, message, error: error, stackTrace: stackTrace);
  }

  void info(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, tag, message, error: error, stackTrace: stackTrace);
  }

  void warning(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, tag, message, error: error, stackTrace: stackTrace);
  }

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  void critical(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.critical, tag, message, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    _logStreamController.add(entry);

    if (_logs.length > maxLogsInMemory) {
      _logs.removeRange(0, _logs.length - maxLogsInMemory);
    }

    unawaited(_saveToFile(entry));

    if (_database != null && _config.shouldSaveLevel(level)) {
      if (kDebugMode) {
        debugPrint(
          'Saving ${level.name} log to DB (shouldSave: ${_config.shouldSaveLevel(level)})',
        );
      }
      unawaited(_saveToDatabase(entry));
    } else if (kDebugMode) {
      debugPrint(
        'Skipping DB save for ${level.name} (db null: ${_database == null}, shouldSave: ${_config.shouldSaveLevel(level)})',
      );
    }

    if (kDebugMode) {
      print(entry.toFormattedString());
    }
  }

  Future<void> _saveToDatabase(LogEntry entry) async {
    try {
      if (_database == null) {
        debugPrint('Database is null, cannot save log');
        return;
      }

      _database!.insertLog(
        AppLogsCompanion.insert(
          timestamp: entry.timestamp,
          level: entry.level.name,
          tag: entry.tag,
          message: entry.message,
          error: Value(entry.error?.toString()),
          stackTrace: Value(entry.stackTrace?.toString()),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving log to database: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _saveToFile(LogEntry entry) async {
    try {
      final file = await _getLogFile();

      if (await file.exists()) {
        final size = await file.length();
        if (size > maxLogFileSize) {
          await _rotateLogFile();
        }
      }

      await file.writeAsString(
        entry.toFormattedString(),
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Error saving log to file: $e');
    }
  }

  Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_logs.txt');
  }

  Future<void> _rotateLogFile() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final backupFile = File('${directory.path}/app_logs_$timestamp.txt');
        await file.rename(backupFile.path);
      }
    } catch (e) {
      debugPrint('Error rotating log file: $e');
    }
  }

  void clearLogs() {
    _logs.clear();
    info('AppLogger', 'Logs cleared from memory');
  }

  Future<void> clearLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (var file in files) {
        if (file.path.contains('app_logs')) {
          await file.delete();
        }
      }

      info('AppLogger', 'Log files cleared');
    } catch (e) {
      error('AppLogger', 'Error clearing log files', error: e);
    }
  }

  Future<void> clearDatabaseLogs() async {
    try {
      if (_database != null) {
        await _database!.deleteAllLogs();
        info('AppLogger', 'Database logs cleared');
      }
    } catch (e) {
      error('AppLogger', 'Error clearing database logs', error: e);
    }
  }

  Future<int> cleanOldLogs() async {
    try {
      if (_database == null) return 0;

      final cutoffDate = _config.cutoffDate;
      final deletedCount = await _database!.deleteOldLogs(cutoffDate);

      if (deletedCount > 0) {
        info(
          'AppLogger',
          'Cleaned $deletedCount old logs (older than $cutoffDate)',
        );
      }

      return deletedCount;
    } catch (e) {
      error('AppLogger', 'Error cleaning old logs', error: e);
      return 0;
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      if (_database == null) {
        return {'total': 0, 'byLevel': {}};
      }

      final total = await _database!.getLogsCount();
      final byLevel = <String, int>{};

      for (var level in LogLevel.values) {
        final logs = await _database!.getLogsByLevel(level.name);
        byLevel[level.name] = logs.length;
      }

      return {
        'total': total,
        'byLevel': byLevel,
        'retentionDays': _config.retentionDays,
        'cutoffDate': _config.cutoffDate.toIso8601String(),
      };
    } catch (e) {
      error('AppLogger', 'Error getting database stats', error: e);
      return {'total': 0, 'byLevel': {}, 'error': e.toString()};
    }
  }

  Future<List<AppLog>> getLogsFromDatabase({LogLevel? level}) async {
    try {
      if (_database == null) return [];

      if (level != null) {
        return await _database!.getLogsByLevel(level.name);
      }

      return await _database!.getAllLogs();
    } catch (e) {
      error('AppLogger', 'Error getting logs from database', error: e);
      return [];
    }
  }

  /// Get logs from database with pagination (newest first)
  Future<List<AppLog>> getLogsFromDatabasePaginated({
    required int limit,
    required int offset,
    LogLevel? level,
  }) async {
    try {
      if (_database == null) return [];

      return await _database!.getLogsPaginated(
        limit: limit,
        offset: offset,
        level: level?.name,
      );
    } catch (e) {
      error(
        'AppLogger',
        'Error getting paginated logs from database',
        error: e,
      );
      return [];
    }
  }

  Future<List<AppLog>> getLogsFromDatabaseByTimeRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      if (_database == null) return [];

      return await _database!.getLogsByTimeRange(start, end);
    } catch (e) {
      error('AppLogger', 'Error getting logs by time range', error: e);
      return [];
    }
  }

  Future<String> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportDir = Directory('${directory.path}/logs_export_$timestamp');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      debugPrint('[AppLogger] Export directory created: ${exportDir.path}');

      final memoryLogsFile = File('${exportDir.path}/logs_memoria.log');
      final memoryBuffer = StringBuffer();
      memoryBuffer.writeln('=== LOGS DA MEMÓRIA ===');
      memoryBuffer.writeln(
        'Exportado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
      );
      memoryBuffer.writeln('Total de logs: ${_logs.length}');
      memoryBuffer.writeln('=' * 80);
      memoryBuffer.writeln();

      if (_logs.isEmpty) {
        memoryBuffer.writeln('Nenhum log em memória.');
      } else {
        for (var log in _logs) {
          memoryBuffer.write(log.toFormattedString());
          memoryBuffer.writeln();
        }
      }

      await memoryLogsFile.writeAsString(memoryBuffer.toString());
      debugPrint('[AppLogger] Memory logs written: ${_logs.length} logs');

      final dbLogsFile = File('${exportDir.path}/logs_banco.log');
      final dbBuffer = StringBuffer();
      dbBuffer.writeln('=== LOGS DO BANCO DE DADOS ===');
      dbBuffer.writeln(
        'Exportado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
      );

      if (_database != null) {
        final dbLogs = await _database!.getAllLogs();
        dbBuffer.writeln('Total de logs: ${dbLogs.length}');
        dbBuffer.writeln('=' * 80);
        dbBuffer.writeln();

        if (dbLogs.isEmpty) {
          dbBuffer.writeln('Nenhum log no banco de dados.');
        } else {
          for (var log in dbLogs) {
            dbBuffer.writeln(
              '[${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp)}] '
              '[${log.level.toUpperCase()}] [${log.tag}] ${log.message}',
            );
            if (log.error != null) {
              dbBuffer.writeln('Error: ${log.error}');
            }
            if (log.stackTrace != null) {
              dbBuffer.writeln('StackTrace:');
              dbBuffer.writeln(log.stackTrace);
            }
            dbBuffer.writeln();
          }
        }
        debugPrint(
          '💾 [AppLogger] Database logs written: ${dbLogs.length} logs',
        );
      } else {
        dbBuffer.writeln('Total de logs: 0');
        dbBuffer.writeln('=' * 80);
        dbBuffer.writeln();
        dbBuffer.writeln('Banco de dados não inicializado.');
        debugPrint('[AppLogger] Database not initialized');
      }

      await dbLogsFile.writeAsString(dbBuffer.toString());

      final infoFile = File('${exportDir.path}/info.txt');
      final infoBuffer = StringBuffer();
      infoBuffer.writeln('=== INFORMAÇÕES DA EXPORTAÇÃO ===');
      infoBuffer.writeln(
        'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
      );
      infoBuffer.writeln('Logs em Memória: ${_logs.length}');
      if (_database != null) {
        final dbLogs = await _database!.getAllLogs();
        infoBuffer.writeln('Logs no Banco: ${dbLogs.length}');
        infoBuffer.writeln('Total Geral: ${_logs.length + dbLogs.length}');
      } else {
        infoBuffer.writeln('Logs no Banco: 0 (banco não inicializado)');
        infoBuffer.writeln('Total Geral: ${_logs.length}');
      }
      infoBuffer.writeln('=' * 80);
      infoBuffer.writeln();
      infoBuffer.writeln('Arquivos incluídos:');
      infoBuffer.writeln(
        '  - logs_memoria.log: Logs em memória da sessão atual',
      );
      infoBuffer.writeln(
        '  - logs_banco.log: Logs persistidos no banco de dados',
      );

      await infoFile.writeAsString(infoBuffer.toString());
      debugPrint('[AppLogger] Info file created');

      final files = await exportDir.list().toList();
      debugPrint('[AppLogger] Files in export directory: ${files.length}');
      for (var entity in files) {
        if (entity is File) {
          final size = await entity.length();
          debugPrint('   - ${entity.path.split('/').last}: $size bytes');
        }
      }

      final zipPath = '${directory.path}/mooze_logs_$timestamp.zip';
      debugPrint('[AppLogger] Creating ZIP: $zipPath');

      final archive = Archive();

      for (var entity in files) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          debugPrint('   Adding file to archive: $fileName');

          final fileBytes = await entity.readAsBytes();
          debugPrint('   File size: ${fileBytes.length} bytes');

          final archiveFile = ArchiveFile(
            fileName,
            fileBytes.length,
            fileBytes,
          );
          archive.addFile(archiveFile);
        }
      }

      debugPrint('[AppLogger] Archive has ${archive.length} files');

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes.isEmpty) {
        throw Exception('Failed to encode ZIP file');
      }

      debugPrint('[AppLogger] ZIP encoded: ${zipBytes.length} bytes');

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      if (!await zipFile.exists()) {
        throw Exception('ZIP file was not created');
      }

      final zipSize = await zipFile.length();
      debugPrint('[AppLogger] ZIP created successfully: $zipSize bytes');

      await exportDir.delete(recursive: true);
      debugPrint('[AppLogger] Temporary directory deleted');

      info('AppLogger', 'Logs exported to: $zipPath');
      return zipPath;
    } catch (e, stackTrace) {
      error(
        'AppLogger',
        'Error exporting logs',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<LogEntry> filterByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<LogEntry> filterByTag(String tag) {
    return _logs.where((log) => log.tag.contains(tag)).toList();
  }

  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) {
      return log.timestamp.isAfter(start) && log.timestamp.isBefore(end);
    }).toList();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _logStreamController.close();
  }
}
