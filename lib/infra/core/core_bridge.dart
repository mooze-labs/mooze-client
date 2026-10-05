import 'dart:async';

import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:mooze_mobile/database/database.dart';

import '../../domain/entities/chain.dart';
import '../../shared/logging/structured_logger.dart';
import '../migration/flutter_data_exporter.dart';
import 'core_dto_mapper.dart';

/// Opens mooze-core for the app and runs the one-time data import.
///
/// Steps of [open]:
/// 1. Initialize `MoozeCoreLib` once per process.
/// 2. Open the core in `<application support>/mooze_core` with the
///    Electrum backend and the custom node URLs from SharedPreferences.
/// 3. If the core is not migrated, export the Flutter data and import it.
///
/// A failed import does not block the wallet. The core keeps its migration
/// marker unset, so the import runs again on the next launch.
class MoozeCoreBridge {
  MoozeCoreBridge({
    required this.logger,
    Future<void> Function()? initLib,
    Future<MoozeCore> Function(CoreConfig config)? opener,
    Future<String> Function()? dataDirResolver,
  })  : _initLib = initLib ?? _initOnce,
        _opener = opener ?? ((config) => MoozeCore.open(config: config)),
        _dataDirResolver = dataDirResolver ?? _defaultDataDir;

  final StructuredLogger logger;
  final Future<void> Function() _initLib;
  final Future<MoozeCore> Function(CoreConfig config) _opener;
  final Future<String> Function() _dataDirResolver;

  /// SharedPreferences key of the custom Bitcoin node.
  static const String bitcoinNodeUrlKey = 'bitcoin_node_url';

  /// SharedPreferences key of the custom Liquid node.
  static const String liquidNodeUrlKey = 'liquid_node_url';

  /// Subdirectory of the application support directory that the core owns.
  static const String dataDirName = 'mooze_core';

  static Future<void>? _libInit;

  /// Initializes `MoozeCoreLib` once. A failed init clears the cache, so
  /// the next call tries again.
  static Future<void> _initOnce() {
    return _libInit ??= MoozeCoreLib.init().catchError((Object e) {
      _libInit = null;
      throw e;
    });
  }

  static Future<String> _defaultDataDir() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$dataDirName';
  }

  /// Builds the [CoreConfig] for [network] from the stored node URLs.
  Future<CoreConfig> buildConfig({
    required AppNetwork network,
    required SharedPreferences preferences,
  }) async {
    return CoreConfig(
      dataDir: await _dataDirResolver(),
      network: networkToDto(network),
      // The app uses Electrum today, through the lwk/bdk services.
      backend: BackendDto.electrum,
      bitcoinNodeUrl: preferences.getString(bitcoinNodeUrlKey) ?? '',
      liquidNodeUrl: preferences.getString(liquidNodeUrlKey) ?? '',
    );
  }

  /// Opens the core and runs the one-time import.
  ///
  /// [snapshotJson] builds the import snapshot. It runs only when the core
  /// is not migrated yet.
  Future<MoozeCore> open({
    required AppNetwork network,
    required SharedPreferences preferences,
    required Future<String> Function() snapshotJson,
  }) async {
    final t0 = DateTime.now();
    await _initLib();
    final config = await buildConfig(network: network, preferences: preferences);
    final core = await _opener(config);
    logger.info('core.opened', {
      'network': network.name,
      'custom_bitcoin_node': config.bitcoinNodeUrl.isNotEmpty,
      'custom_liquid_node': config.liquidNodeUrl.isNotEmpty,
      'dur_ms': DateTime.now().difference(t0).inMilliseconds,
    });
    await runImport(core, snapshotJson);
    return core;
  }

  /// Runs the one-time Flutter data import if the core needs it. Never
  /// throws: every failure is logged, and the next launch tries again.
  Future<void> runImport(
    MoozeCore core,
    Future<String> Function() snapshotJson,
  ) async {
    try {
      if (await core.isMigrated()) {
        logger.debug('core.import.skip', {'reason': 'already_migrated'});
        return;
      }
      final t0 = DateTime.now();
      final json = await snapshotJson();
      final report = await core.importFlutterSnapshot(snapshotJson: json);
      logger.info('core.import.done', {
        'already_done': report.alreadyDone,
        'copied': {for (final c in report.copied) c.table: c.count},
        'skipped_count': report.skipped.length,
        'dur_ms': DateTime.now().difference(t0).inMilliseconds,
      });
      for (final s in report.skipped) {
        logger.warn('core.import.skipped_row',
            {'table': s.table, 'key': s.key, 'reason': s.reason});
      }
    } catch (e, st) {
      final detail = e is CoreError ? coreErrorMessage(e) : '$e';
      logger.error('core.import.failed', {'error': detail, 'will_retry': true},
          error: e, stackTrace: st);
    }
  }

  /// Opens the core for the app, with the snapshot built by
  /// [FlutterDataExporter] from the app databases.
  Future<MoozeCore> openForApp({
    required AppNetwork network,
    required AppDatabase appDatabase,
    required sqlite.Database transactionDatabase,
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    return open(
      network: network,
      preferences: prefs,
      snapshotJson: () => FlutterDataExporter(
        appDatabase: appDatabase,
        transactionDatabase: transactionDatabase,
        preferences: prefs,
      ).exportJson(),
    );
  }
}
