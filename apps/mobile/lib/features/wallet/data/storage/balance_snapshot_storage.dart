import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/balance_snapshot_store.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// [BalanceSnapshotStore] backed by [SharedPreferences].
///
/// One key per wallet: `balance_snapshot_v1_<walletId>`. The value is a JSON
/// object:
///
/// ```json
/// { "savedAt": 1700000000000, "balances": { "<assetId>": "<sats>" } }
/// ```
///
/// BigInt amounts are persisted as decimal strings — JSON has no integer type
/// wide enough to hold satoshi totals safely, and `double` would lose
/// precision. All operations swallow their own errors so a storage fault can
/// never break a sync or a wallet open.
class SharedPreferencesBalanceSnapshotStore implements BalanceSnapshotStore {
  /// Shared prefix for every per-wallet snapshot key. The `_v1_` segment
  /// lets the serialization format evolve without colliding with old data.
  static const String keyPrefix = 'balance_snapshot_v1_';

  String _keyFor(String walletId) => '$keyPrefix$walletId';

  @override
  Future<void> save(String walletId, BalanceSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final balances = <String, String>{};
      snapshot.balances.forEach((asset, amount) {
        balances[asset.id] = amount.toString();
      });
      final payload = jsonEncode({
        'savedAt': snapshot.savedAt.millisecondsSinceEpoch,
        'balances': balances,
      });
      await prefs.setString(_keyFor(walletId), payload);
    } catch (_) {
      // Best-effort persistence: never let a write fault abort a sync.
    }
  }

  @override
  Future<BalanceSnapshot?> load(String walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(walletId));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAtMs = decoded['savedAt'] as int?;
      final rawBalances = decoded['balances'];
      if (savedAtMs == null || rawBalances is! Map) return null;

      final balances = <Asset, BigInt>{};
      rawBalances.forEach((assetId, value) {
        final amount = BigInt.tryParse(value.toString());
        if (amount != null) {
          balances[Asset.fromId(assetId as String)] = amount;
        }
      });

      return BalanceSnapshot(
        balances: balances,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
    } catch (_) {
      // Corrupt entry: treat as absent rather than crashing the wallet open.
      return null;
    }
  }

  @override
  Future<void> clear(String walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFor(walletId));
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Best-effort.
    }
  }
}
