import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/infra/migration/flutter_data_exporter.dart';

import '../../shared/database_test_helpers.dart';

/// Golden file shared with the Rust importer test in
/// `mooze-core/tests/flutter_snapshot.rs`. A format change must update
/// both sides, or one of the two tests fails.
const _fixturePath = 'mooze-core/tests/fixtures/flutter_snapshot_v1.json';

final _t0 = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

/// Creates the `mooze_v2.db` tables, as `TransactionDatabase._migrate` does.
sqlite.Database _openV2() {
  final db = sqlite.sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE transactions (
      id TEXT NOT NULL, chain TEXT NOT NULL, direction TEXT NOT NULL,
      status TEXT NOT NULL, amount_sat INTEGER NOT NULL, fee_sat INTEGER NOT NULL,
      timestamp_ms INTEGER NOT NULL, confirmations INTEGER NOT NULL DEFAULT 0,
      asset_id TEXT, address TEXT, label TEXT, from_asset_id TEXT, to_asset_id TEXT,
      sent_amount_sat INTEGER, received_amount_sat INTEGER, source TEXT,
      swap_lockup_tx_id TEXT, swap_claim_tx_id TEXT, breez_swap_id TEXT,
      PRIMARY KEY (id, chain)
    )
  ''');
  db.execute('''
    CREATE TABLE notified_tx_ids (
      chain TEXT NOT NULL, tx_id TEXT NOT NULL, notified_at_ms INTEGER NOT NULL,
      PRIMARY KEY (chain, tx_id)
    )
  ''');
  db.execute(
    'CREATE TABLE notification_meta (meta_key TEXT PRIMARY KEY, meta_value TEXT NOT NULL)',
  );
  return db;
}

void main() {
  group('with data in every source', _seededTests);

  test('empty sources give an empty snapshot', () async {
    final emptyDb = buildInMemoryDatabase();
    final emptyV2 = _openV2();
    SharedPreferences.setMockInitialValues({});
    final snapshot = await FlutterDataExporter(
      appDatabase: emptyDb,
      transactionDatabase: emptyV2,
      preferences: await SharedPreferences.getInstance(),
    ).buildSnapshot();
    expect(snapshot['version'], FlutterDataExporter.snapshotVersion);
    expect(snapshot['transactions'], isEmpty);
    expect(snapshot['preferences'], isEmpty);
    await emptyDb.close();
    emptyV2.dispose();
  });
}

void _seededTests() {
  late AppDatabase appDb;
  late sqlite.Database v2;

  setUp(() async {
    appDb = buildInMemoryDatabase();
    v2 = _openV2();

    v2.execute(
      "INSERT INTO transactions (id, chain, direction, status, amount_sat, fee_sat, "
      "timestamp_ms, confirmations, asset_id, label, source) VALUES "
      "('aa', 'liquid', 'incoming', 'confirmed', 5000, 0, 1700000000000, 3, "
      "'6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d', 'rent', 'lwk')",
    );
    v2.execute(
      "INSERT INTO notified_tx_ids VALUES ('liquid', 'aa', 1700000001000)",
    );
    v2.execute(
      "INSERT INTO notification_meta VALUES ('baseline_completed', '1'), "
      "('wallet_imported_at_ms', '1690000000000')",
    );

    await appDb.into(appDb.swaps).insert(SwapsCompanion.insert(
          sendAsset: 'LBTC',
          receiveAsset: 'USDT',
          sendAmount: BigInt.from(1000),
          receiveAmount: BigInt.from(650),
          createdAt: Value(_t0),
          provider: const Value('sideswap'),
          status: const Value('completed'),
          direction: const Value('asset_swap'),
          txId: const Value('cc'),
          walletId: const Value('w1'),
        ));
    await appDb.into(appDb.pegs).insert(PegsCompanion.insert(
          orderId: 'ord1',
          pegIn: true,
          sideswapAddress: 'bc1qdeposit',
          payoutAddress: 'lq1payout',
          amount: 100000,
          createdAt: Value(_t0),
          walletId: const Value('w1'),
          status: const Value('pending'),
          fundingTxId: const Value('ff'),
          updatedAt: Value(_t0.add(const Duration(seconds: 50))),
          metadata: const Value('{"fee":12}'),
        ));
    await appDb.into(appDb.deposits).insert(DepositsCompanion.insert(
          depositId: 'dep1',
          assetId:
              '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
          amountInCents: 2500,
          createdAt: Value(_t0),
          status: 'finished',
          assetAmount: Value(BigInt.from(2500000000)),
          blockchainTxid: const Value('dd'),
          pixKey: '000201',
        ));
    await appDb.into(appDb.products).insert(ProductsCompanion.insert(
          name: 'Café',
          price: 7.5,
          createdAt: Value(_t0),
        ));
    await appDb.into(appDb.syncMetadata).insert(SyncMetadataCompanion.insert(
          datasource: 'lwk',
          lastSyncTime: _t0,
          transactionCount: 42,
          syncStatus: 'ok',
        ));
    await appDb
        .into(appDb.favoritePayerEntries)
        .insert(FavoritePayerEntriesCompanion.insert(
          label: 'Ana',
          cpf: '12345678901',
          createdAt: Value(_t0),
        ));

    SharedPreferences.setMockInitialValues({
      'bitcoin_node_url': 'ssl://my.node:50002',
      'device_id': 'dev-123',
      'favorite_assets': ['btc', 'usdt'],
      'hasSeenPixTutorial': true,
      'merchant_mode_active': true,
      'user_verification_level': 2,
      // A secret in the wrong store must not leave the device.
      'mnemonic_mainWallet': 'abandon abandon abandon',
    });
  });

  tearDown(() async {
    await appDb.close();
    v2.dispose();
  });

  Future<FlutterDataExporter> exporter() async => FlutterDataExporter(
        appDatabase: appDb,
        transactionDatabase: v2,
        preferences: await SharedPreferences.getInstance(),
      );

  test('snapshot matches the golden file the Rust importer reads', () async {
    final snapshot = await (await exporter()).buildSnapshot();
    final golden = jsonDecode(File(_fixturePath).readAsStringSync());
    // Round-trip through JSON so types compare as the core will see them.
    expect(jsonDecode(jsonEncode(snapshot)), equals(golden));
  });

  test('never exports secrets from preferences', () async {
    final json = await (await exporter()).exportJson();
    expect(json, isNot(contains('mnemonic_mainWallet')));
    expect(json, isNot(contains('abandon')));
  });
}
