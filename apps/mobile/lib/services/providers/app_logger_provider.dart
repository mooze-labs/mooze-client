import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/log_config.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

/// Wires the legacy [AppDatabase] into the singleton [AppLoggerService]
/// the first time the logger is read. The V2 boot pipeline doesn't touch
/// the logger, so without this the singleton stays uninitialized — DB
/// logs, the export's `dbLogs` section, and the export's `swaps` section
/// (which reads via `_database`) would all come back empty.
///
/// `initialize` is idempotent and sets `_database` synchronously before
/// its first `await`, so callers reading the provider get a fully-wired
/// logger even though the cleanup task is unawaited.
final appLoggerProvider = Provider<AppLoggerService>((ref) {
  final logger = AppLoggerService();
  final db = ref.read(appDatabaseProvider);
  unawaited(
    logger.initialize(
      db,
      config: kDebugMode ? LogConfig.development : LogConfig.production,
    ),
  );
  return logger;
});
