import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/wallet/data/storage/balance_snapshot_storage.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/balance_snapshot_store.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

void main() {
  late SharedPreferencesBalanceSnapshotStore store;

  BalanceSnapshot snap(Map<Asset, BigInt> b, [int ms = 0]) => BalanceSnapshot(
        balances: b,
        savedAt: DateTime.fromMillisecondsSinceEpoch(ms),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = SharedPreferencesBalanceSnapshotStore();
  });

  group('SharedPreferencesBalanceSnapshotStore', () {
    test('load returns null when nothing is persisted', () async {
      expect(await store.load('wallet-a'), isNull);
    });

    test('save then load round-trips balances and timestamp', () async {
      final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await store.save(
        'wallet-a',
        BalanceSnapshot(
          balances: {
            Asset.btc: BigInt.from(123456),
            // A value far larger than a 53-bit double can hold, to prove the
            // string serialization keeps full BigInt precision.
            Asset.usdt: BigInt.parse('999999999999999999'),
          },
          savedAt: at,
        ),
      );

      final loaded = await store.load('wallet-a');

      expect(loaded, isNotNull);
      expect(loaded!.balances[Asset.btc], BigInt.from(123456));
      expect(loaded.balances[Asset.usdt], BigInt.parse('999999999999999999'));
      expect(loaded.savedAt, at);
    });

    test('snapshots are isolated per walletId (no cross-wallet leak)',
        () async {
      await store.save('wallet-a', snap({Asset.btc: BigInt.from(10)}));
      await store.save('wallet-b', snap({Asset.btc: BigInt.from(20)}));

      expect((await store.load('wallet-a'))!.balances[Asset.btc],
          BigInt.from(10));
      expect((await store.load('wallet-b'))!.balances[Asset.btc],
          BigInt.from(20));
    });

    test('save overwrites the previous snapshot for the same wallet',
        () async {
      await store.save('wallet-a', snap({Asset.btc: BigInt.from(10)}, 0));
      await store.save('wallet-a', snap({Asset.btc: BigInt.from(50)}, 1));

      final loaded = await store.load('wallet-a');
      expect(loaded!.balances[Asset.btc], BigInt.from(50));
    });

    test('clear removes only the given wallet', () async {
      await store.save('wallet-a', snap({Asset.btc: BigInt.from(10)}));
      await store.save('wallet-b', snap({Asset.btc: BigInt.from(20)}));

      await store.clear('wallet-a');

      expect(await store.load('wallet-a'), isNull);
      expect(await store.load('wallet-b'), isNotNull);
    });

    test('clearAll removes every wallet snapshot but leaves unrelated keys',
        () async {
      SharedPreferences.setMockInitialValues({'unrelated_key': 'keep-me'});
      store = SharedPreferencesBalanceSnapshotStore();
      await store.save('wallet-a', snap({Asset.btc: BigInt.from(10)}));
      await store.save('wallet-b', snap({Asset.btc: BigInt.from(20)}));

      await store.clearAll();

      expect(await store.load('wallet-a'), isNull);
      expect(await store.load('wallet-b'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unrelated_key'), 'keep-me');
    });

    test('load returns null for a corrupt (non-JSON) entry', () async {
      SharedPreferences.setMockInitialValues({
        '${SharedPreferencesBalanceSnapshotStore.keyPrefix}wallet-a': 'not-json',
      });
      store = SharedPreferencesBalanceSnapshotStore();

      expect(await store.load('wallet-a'), isNull);
    });

    test('an empty balance map round-trips as an empty (not null) snapshot',
        () async {
      await store.save('wallet-a', snap(const {}, 42));

      final loaded = await store.load('wallet-a');
      expect(loaded, isNotNull);
      expect(loaded!.balances, isEmpty);
      expect(loaded.savedAt, DateTime.fromMillisecondsSinceEpoch(42));
    });
  });
}
