import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/infra/core/core_bridge.dart';
import 'package:mooze_mobile/shared/logging/structured_logger.dart';

import 'core_test_fixtures.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockCore core;
  late MemoryLogger logger;
  late List<CoreConfig> opened;
  late int libInits;
  late MoozeCoreBridge bridge;

  setUp(() {
    core = _MockCore();
    logger = MemoryLogger();
    opened = [];
    libInits = 0;
    bridge = MoozeCoreBridge(
      logger: logger,
      initLib: () async => libInits++,
      opener: (config) async {
        opened.add(config);
        return core;
      },
      dataDirResolver: () async => '/support/mooze_core',
    );
  });

  test('builds the config from the stored node URLs', () async {
    SharedPreferences.setMockInitialValues({
      'bitcoin_node_url': 'ssl://btc.example:50002',
    });
    final prefs = await SharedPreferences.getInstance();
    when(() => core.isMigrated()).thenAnswer((_) async => true);

    await bridge.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => fail('import must not run'),
    );

    expect(libInits, 1);
    final c = opened.single;
    expect(c.dataDir, '/support/mooze_core');
    expect(c.network, NetworkDto.mainnet);
    expect(c.backend, BackendDto.electrum);
    expect(c.bitcoinNodeUrl, 'ssl://btc.example:50002');
    expect(c.liquidNodeUrl, '');
    verifyNever(() =>
        core.importFlutterSnapshot(snapshotJson: any(named: 'snapshotJson')));
  });

  test('imports the snapshot once when the core is not migrated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    when(() => core.isMigrated()).thenAnswer((_) async => false);
    when(() => core.importFlutterSnapshot(
            snapshotJson: any(named: 'snapshotJson')))
        .thenAnswer((_) async => const MigrationReportDto(
              alreadyDone: false,
              copied: [TableCountDto(table: 'transactions', count: 3)],
              skipped: [
                SkippedRowDto(table: 'swaps', key: '7', reason: 'bad json'),
              ],
            ));

    final opened = await bridge.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => '{"version":1}',
    );

    expect(opened, same(core));
    verify(() => core.importFlutterSnapshot(snapshotJson: '{"version":1}'))
        .called(1);
    final done = logger.logs.firstWhere((r) => r.tag == 'core.import.done');
    expect(done.fields['copied'], {'transactions': 3});
    expect(done.fields['skipped_count'], 1);
    expect(logger.hasTag('core.import.skipped_row'), isTrue);
  });

  test('a failed import is logged and does not block the core', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    when(() => core.isMigrated()).thenAnswer((_) async => false);
    when(() => core.importFlutterSnapshot(
            snapshotJson: any(named: 'snapshotJson')))
        .thenThrow(const CoreError(
            kind: CoreErrorKind.storage, message: 'storage: disk full'));

    final opened = await bridge.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => '{}',
    );

    expect(opened, same(core));
    final failed = logger.logs.firstWhere((r) => r.tag == 'core.import.failed');
    expect(failed.level, LogLevel.error);
    expect(failed.fields['error'], 'storage: disk full');
    expect(failed.fields['will_retry'], isTrue);
  });

  test('a failed snapshot export is logged and does not block', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    when(() => core.isMigrated()).thenAnswer((_) async => false);

    await bridge.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => throw StateError('db closed'),
    );

    expect(logger.hasTag('core.import.failed'), isTrue);
    verifyNever(() =>
        core.importFlutterSnapshot(snapshotJson: any(named: 'snapshotJson')));
  });

  test('configure runs right after open, before the import', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final order = <String>[];
    when(() => core.isMigrated()).thenAnswer((_) async {
      order.add('isMigrated');
      return true;
    });
    final configured = MoozeCoreBridge(
      logger: logger,
      initLib: () async {},
      opener: (_) async {
        order.add('open');
        return core;
      },
      dataDirResolver: () async => '/d',
      configure: (c) async {
        expect(c, same(core));
        order.add('configure');
      },
    );

    await configured.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => '{}',
    );

    expect(order, ['open', 'configure', 'isMigrated']);
  });

  test('a failed configure is logged and does not block the core', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    when(() => core.isMigrated()).thenAnswer((_) async => true);
    final configured = MoozeCoreBridge(
      logger: logger,
      initLib: () async {},
      opener: (_) async => core,
      dataDirResolver: () async => '/d',
      configure: (_) async => throw const CoreError(
          kind: CoreErrorKind.invalidState, message: 'boom'),
    );

    final opened = await configured.open(
      network: AppNetwork.mainnet,
      preferences: prefs,
      snapshotJson: () async => '{}',
    );

    expect(opened, same(core));
    final failed =
        logger.logs.firstWhere((r) => r.tag == 'core.configure.failed');
    expect(failed.fields['error'], 'boom');
  });
}
