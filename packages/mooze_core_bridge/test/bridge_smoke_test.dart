import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

/// Calls the real native library from Dart, on the host.
///
/// Build it first with `cargo build` in `rust/`. Set `MOOZE_CORE_BRIDGE_LIB`
/// to use a library built elsewhere, for example with `CARGO_TARGET_DIR`.
/// The test skips when the library is missing, so `flutter test` still runs
/// on machines without Rust.
const _abandon =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

String? _hostLibrary() {
  final name = Platform.isMacOS
      ? 'libmooze_core_bridge.dylib'
      : Platform.isWindows
          ? 'mooze_core_bridge.dll'
          : 'libmooze_core_bridge.so';
  final path =
      Platform.environment['MOOZE_CORE_BRIDGE_LIB'] ?? 'rust/target/debug/$name';
  return File(path).existsSync() ? path : null;
}

void main() {
  final library = _hostLibrary();

  setUpAll(() async {
    if (library != null) {
      await MoozeCoreLib.init(externalLibrary: ExternalLibrary.open(library));
    }
  });

  Future<MoozeCore> openCore() async {
    final dir = await Directory.systemTemp.createTemp('mooze-core-bridge-');
    addTearDown(() => dir.delete(recursive: true));
    return MoozeCore.open(
      config: CoreConfig(
        dataDir: dir.path,
        network: NetworkDto.mainnet,
        backend: BackendDto.electrum,
        bitcoinNodeUrl: '',
        liquidNodeUrl: '',
      ),
    );
  }

  test('derives the same first addresses as the Flutter app', () async {
    final core = await openCore();
    await core.bitcoinConnect(mnemonic: _abandon);
    final btc = await core.bitcoinReceiveAddress();
    expect(btc.address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');

    await core.liquidConnect(mnemonic: _abandon);
    final lq = await core.liquidReceiveAddress();
    expect(lq.address, startsWith('lq1'));
    expect(await core.liquidTransactions(), isEmpty);
  }, skip: library == null ? 'native library not built' : false);

  test('imports the golden snapshot once', () async {
    final core = await openCore();
    expect(await core.isMigrated(), isFalse);
    final json = File('../../mooze-core/tests/fixtures/flutter_snapshot_v1.json')
        .readAsStringSync();
    final report = await core.importFlutterSnapshot(snapshotJson: json);
    expect(report.alreadyDone, isFalse);
    expect(report.skipped, isEmpty);
    expect(
      report.copied.firstWhere((c) => c.table == 'transactions').count,
      1,
    );
    expect(await core.isMigrated(), isTrue);
    final again = await core.importFlutterSnapshot(snapshotJson: json);
    expect(again.alreadyDone, isTrue);
  }, skip: library == null ? 'native library not built' : false);

  test('calls before connect throw CoreError', () async {
    final core = await openCore();
    await expectLater(
      core.bitcoinBalance(),
      throwsA(isA<CoreError>()
          .having((e) => e.kind, 'kind', CoreErrorKind.invalidState)),
    );
  }, skip: library == null ? 'native library not built' : false);
}
