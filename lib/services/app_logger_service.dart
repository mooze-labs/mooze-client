import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
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
  factory AppLoggerService() => _instance;

  AppLoggerService._internal();

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  // Pending entries staged for the next flush window. Logger calls hit
  // this list, then a 200ms periodic timer drains it into SQLite + the
  // log file in a single batched write per sink. This keeps file/DB
  // I/O off the UI isolate's per-call hot path during HomeScreen mount.
  final List<LogEntry> _pendingLogs = [];
  Timer? _flushTimer;
  bool _flushInFlight = false;

  // Cached at initialize() so per-log calls don't pay the
  // path_provider channel cost on every write.
  File? _cachedLogFile;

  AppDatabase? _database;

  LogConfig _config = LogConfig.production;

  Timer? _cleanupTimer;

  Stream<LogEntry> get logStream => _logStreamController.stream;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  static const int maxLogsInMemory = 1000;

  static const int maxLogFileSize = 5 * 1024 * 1024;

  static const Duration _flushInterval = Duration(milliseconds: 200);

  Future<void> initialize(AppDatabase database, {LogConfig? config}) async {
    if (_database != null) {
      // Already wired. Re-running would leak a second cleanup timer.
      if (config != null) {
        _config = config;
      }
      return;
    }

    _database = database;

    if (config != null) {
      _config = config;
    }

    // Pre-resolve the log file path so per-call writes never hit
    // path_provider's platform channel.
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cachedLogFile = File('${directory.path}/app_logs.txt');
    } catch (_) {
      // Path resolution failure leaves _cachedLogFile null; flush
      // gracefully no-ops the file sink until the next cold boot.
    }

    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      cleanOldLogs();
    });

    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushPendingLogs());

    await cleanOldLogs();
    // Flush any logs buffered before initialize() completed.
    unawaited(_flushPendingLogs());
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

    // Stage for the next flush window. Critical events are flushed
    // immediately so a crash can't lose them; everything else rides the
    // 200ms timer batch.
    _pendingLogs.add(entry);
    if (level == LogLevel.critical) {
      unawaited(_flushPendingLogs());
    }
  }

  /// Drains [_pendingLogs] in one DB batch + one file append. Runs on
  /// the periodic timer (200ms) and on critical/dispose paths. Guarded
  /// against concurrent flushes so a slow disk write can't cause two
  /// batches to interleave and reorder entries.
  Future<void> _flushPendingLogs() async {
    if (_flushInFlight) return;
    if (_pendingLogs.isEmpty) return;

    _flushInFlight = true;
    try {
      final pending = List<LogEntry>.from(_pendingLogs);
      _pendingLogs.clear();

      // DB sink — single transaction, one round-trip across drift's
      // worker isolate instead of one per entry.
      final db = _database;
      if (db != null) {
        final saveable = pending
            .where((e) => _config.shouldSaveLevel(e.level))
            .toList();
        if (saveable.isNotEmpty) {
          try {
            await db.batch((batch) {
              for (final entry in saveable) {
                batch.insert(
                  db.appLogs,
                  AppLogsCompanion.insert(
                    timestamp: entry.timestamp,
                    level: entry.level.name,
                    tag: entry.tag,
                    message: entry.message,
                    error: Value(entry.error?.toString()),
                    stackTrace: Value(entry.stackTrace?.toString()),
                  ),
                );
              }
            });
          } catch (e) {
            if (kDebugMode) debugPrint('Error batch-saving logs to DB: $e');
          }
        }
      }

      // File sink — single append for the whole batch. Rotation check
      // runs once per flush, not once per entry.
      final file = _cachedLogFile;
      if (file != null) {
        try {
          if (await file.exists()) {
            final size = await file.length();
            if (size > maxLogFileSize) {
              await _rotateLogFile();
            }
          }
          final buffer = StringBuffer();
          for (final entry in pending) {
            buffer.write(entry.toFormattedString());
          }
          await file.writeAsString(buffer.toString(), mode: FileMode.append);
        } catch (e) {
          if (kDebugMode) debugPrint('Error appending logs to file: $e');
        }
      }
    } finally {
      _flushInFlight = false;
    }
  }

  Future<File> _getLogFile() async {
    if (_cachedLogFile != null) return _cachedLogFile!;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs.txt');
    _cachedLogFile = file;
    return file;
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
      debugPrint('Error cleaning old logs: $e');
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

  /// Get logs from database with pagination (newest first). Level and search
  /// are applied at the SQL layer so callers don't have to over-fetch.
  Future<List<AppLog>> getLogsFromDatabasePaginated({
    required int limit,
    required int offset,
    LogLevel? level,
    String? searchQuery,
  }) async {
    try {
      if (_database == null) return [];

      return await _database!.getLogsPaginated(
        limit: limit,
        offset: offset,
        level: level?.name,
        searchQuery: searchQuery,
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

  /// Filtered view over the in-memory ring buffer (newest first).
  /// Mirrors the database-side filter so memory and DB sources share the
  /// same matching semantics.
  List<LogEntry> getMemoryLogsFiltered({
    LogLevel? level,
    String? searchQuery,
  }) {
    Iterable<LogEntry> filtered = _logs.reversed;

    if (level != null) {
      filtered = filtered.where((log) => log.level == level);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        if (log.message.toLowerCase().contains(query)) return true;
        if (log.tag.toLowerCase().contains(query)) return true;
        final errorText = log.error?.toString().toLowerCase();
        if (errorText != null && errorText.contains(query)) return true;
        final stackText = log.stackTrace?.toString().toLowerCase();
        if (stackText != null && stackText.contains(query)) return true;
        return false;
      });
    }

    return filtered.toList();
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

  /// Build the export ZIP for the given [walletId]. Swaps and Pegs in the
  /// structured JSON section are scoped to this wallet — pre-walletId
  /// rows (sentinel 'unknown') are not included, matching the in-app
  /// view. Logs are not currently wallet-scoped at the schema level
  /// (`deleteWallet()` wipes them outright on wipe), so they remain
  /// unscoped here.
  ///
  /// [v2Transactions] is the V2 `TransactionStore` snapshot. After the V2
  /// migration the legacy `Transactions` drift table is no longer
  /// populated (V2 services write to `mooze_v2.db` instead), so callers
  /// must pass V2 rows in to keep the export's `transactions` section
  /// non-empty. When omitted, the export falls back to the legacy table
  /// for backwards compatibility with rows written before the V2 cutover.
  Future<String> exportLogs({
    required String walletId,
    List<v2.Transaction>? v2Transactions,
  }) async {
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
      infoBuffer.writeln(
        '  - mooze_export.json: Export estruturado (logs + transactions + swaps)',
      );

      await infoFile.writeAsString(infoBuffer.toString());
      debugPrint('[AppLogger] Info file created');

      // Structured JSON export — primary artifact for support tooling. Holds
      // logs, transactions and swaps in a single document with stable keys
      // so an automated pipeline can ingest it without parsing free text.
      final jsonExport = await _buildStructuredExport(
        walletId: walletId,
        v2Transactions: v2Transactions,
      );
      final jsonFile = File('${exportDir.path}/mooze_export.json');
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonExport),
      );
      debugPrint(
        '[AppLogger] JSON export written: '
        'logs=${(jsonExport['logs'] as List).length} '
        'tx=${(jsonExport['transactions'] as List).length} '
        'swaps=${(jsonExport['swaps'] as List).length}',
      );

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

  /// Build the structured export document used by support tooling.
  ///
  /// Schema (stable — see DECISIONS.md ADR-XXX):
  /// {
  ///   "schemaVersion": 1,
  ///   "exportedAt":   ISO-8601 UTC timestamp,
  ///   "logs":         [LogEntry-shaped objects, newest first],
  ///   "transactions": [Transaction rows, newest first],
  ///   "swaps":        [Swap rows, newest first]
  /// }
  ///
  /// Logs combine both the in-memory ring buffer (which may include levels
  /// not persisted by [LogConfig]) and the database table. Transactions and
  /// swaps come straight from the database — they have no in-memory mirror.
  /// If the database isn't initialized the corresponding sections are empty
  /// arrays rather than missing keys, so consumers can rely on shape.
  Future<Map<String, dynamic>> _buildStructuredExport({
    required String walletId,
    List<v2.Transaction>? v2Transactions,
  }) async {
    final memoryLogs = _logs.reversed.map(_logEntryToJson).toList();

    List<Map<String, dynamic>> dbLogJson = const [];
    List<Map<String, dynamic>> txJson = const [];
    List<Map<String, dynamic>> swapJson = const [];

    if (_database != null) {
      final db = _database!;
      final dbLogs = await db.getAllLogs();
      final swaps = await db.getAllSwaps(walletId: walletId);

      dbLogJson = dbLogs.map(_appLogRowToJson).toList();

      swaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      swapJson = swaps.map(_swapRowToJson).toList();

      // V2 transactions take precedence over the legacy table. Post-V2
      // sync writes to `mooze_v2.db`, leaving the drift `Transactions`
      // table empty for fresh installs. Only fall back to legacy rows
      // when V2 didn't provide a snapshot (e.g. dev tools called the
      // export without ref access).
      if (v2Transactions == null) {
        final txs = await db.getAllTransactions();
        txs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        txJson = txs.map(_transactionRowToJson).toList();
      }
    }

    if (v2Transactions != null) {
      final sorted = [...v2Transactions]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      txJson = sorted.map(_v2TransactionToJson).toList();
    }

    // Memory + DB logs are merged and sorted newest-first; consumers see one
    // unified timeline regardless of which store the entry lived in.
    final mergedLogs = <Map<String, dynamic>>[...memoryLogs, ...dbLogJson];
    mergedLogs.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] as String? ?? '');
      final tb = DateTime.tryParse(b['timestamp'] as String? ?? '');
      if (ta == null || tb == null) return 0;
      return tb.compareTo(ta);
    });

    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'logs': mergedLogs,
      'transactions': txJson,
      'swaps': swapJson,
    };
  }

  Map<String, dynamic> _logEntryToJson(LogEntry e) => {
    'source': 'memory',
    'timestamp': e.timestamp.toUtc().toIso8601String(),
    'level': e.level.name,
    'tag': e.tag,
    'message': e.message,
    if (e.error != null) 'error': e.error.toString(),
    if (e.stackTrace != null) 'stackTrace': e.stackTrace.toString(),
  };

  Map<String, dynamic> _appLogRowToJson(AppLog row) => {
    'source': 'database',
    'id': row.id,
    'timestamp': row.timestamp.toUtc().toIso8601String(),
    'level': row.level,
    'tag': row.tag,
    'message': row.message,
    if (row.error != null) 'error': row.error,
    if (row.stackTrace != null) 'stackTrace': row.stackTrace,
  };

  Map<String, dynamic> _transactionRowToJson(Transaction row) => {
    'id': row.id,
    'assetId': row.assetId,
    // Int64 amounts are serialized as strings to preserve full precision; a
    // signed JSON number would risk silent truncation on consumers that
    // parse to double.
    'amount': row.amount.toString(),
    'type': row.type,
    'status': row.status,
    'blockchain': row.blockchain,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'confirmations': row.confirmations,
    if (row.txHash != null) 'txHash': row.txHash,
    if (row.address != null) 'address': row.address,
    if (row.metadata != null) 'metadata': row.metadata,
  };

  /// V2 transactions live in `mooze_v2.db` and use a different schema
  /// from the legacy drift `Transactions` table. The export keeps the
  /// legacy-shaped keys (`type`, `blockchain`, `amount`) so support
  /// tooling that parsed the v1 export keeps working; V2-only fields
  /// (`feeSat`, `chain`, raw `direction`) are added alongside without
  /// bumping `schemaVersion`.
  ///
  /// Direction → type mapping mirrors `v2_legacy_transactions_provider`:
  /// incoming → "receive", outgoing → "send", selfTransfer → "redeposit",
  /// swap → "swap", internal → "internal".
  Map<String, dynamic> _v2TransactionToJson(v2.Transaction tx) {
    final type = switch (tx.direction) {
      v2.TransactionDirection.incoming => 'receive',
      v2.TransactionDirection.outgoing => 'send',
      v2.TransactionDirection.selfTransfer => 'redeposit',
      v2.TransactionDirection.swap => 'swap',
      v2.TransactionDirection.internal => 'internal',
    };
    final blockchain = tx.chain.name;
    return {
      'id': tx.id,
      if (tx.assetId != null) 'assetId': tx.assetId,
      'amount': tx.amountSat.toString(),
      'feeSat': tx.feeSat.toString(),
      'type': type,
      'direction': tx.direction.name,
      'status': tx.status.name,
      'blockchain': blockchain,
      'chain': tx.chain.name,
      'createdAt': tx.timestamp.toUtc().toIso8601String(),
      'confirmations': tx.confirmations,
      if (tx.address != null) 'address': tx.address,
      if (tx.label != null) 'label': tx.label,
    };
  }

  Map<String, dynamic> _swapRowToJson(Swap row) => {
    'id': row.id,
    'provider': row.provider,
    'direction': row.direction,
    'status': row.status,
    'sendAsset': row.sendAsset,
    'receiveAsset': row.receiveAsset,
    'sendAmount': row.sendAmount.toString(),
    'receiveAmount': row.receiveAmount.toString(),
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    if (row.txId != null) 'txId': row.txId,
    if (row.metadata != null) 'metadata': row.metadata,
  };

  void dispose() {
    _cleanupTimer?.cancel();
    _flushTimer?.cancel();
    // Best-effort final flush so logs buffered right before shutdown
    // still reach the DB / file sink.
    unawaited(_flushPendingLogs());
    _logStreamController.close();
  }
}
