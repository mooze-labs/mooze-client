import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/data/storage/balance_snapshot_storage.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/balance_snapshot_store.dart';

/// Wallet-isolated persistent store for the latest balance snapshot.
///
/// Backed by [SharedPreferences]; entries are keyed by the current walletId
/// (see `walletIdProvider`). Consumed by `allBalancesProvider` (cache-first
/// reads + write-through on successful sync) and by the wallet delete/import
/// cleanup hooks (`buildWalletCleanupHooks`).
final balanceSnapshotStoreProvider = Provider<BalanceSnapshotStore>((ref) {
  return SharedPreferencesBalanceSnapshotStore();
});
