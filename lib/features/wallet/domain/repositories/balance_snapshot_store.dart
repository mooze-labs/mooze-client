import 'package:mooze_mobile/shared/entities/asset.dart';

/// An immutable, locally-persisted view of a wallet's last-known balances.
///
/// Mirrors the shape consumed by `allBalancesProvider` (per-asset satoshi
/// amounts) plus the moment the snapshot was captured, so the UI can show a
/// "values may be out of date" hint when running on cached data.
class BalanceSnapshot {
  const BalanceSnapshot({required this.balances, required this.savedAt});

  /// Per-asset balance in satoshis. Token assets (USDT/DePix) use their
  /// 1e8-scaled integer form, identical to what `balanceMap` returns.
  final Map<Asset, BigInt> balances;

  /// When this snapshot was captured — the timestamp of the successful sync
  /// that produced it.
  final DateTime savedAt;
}

/// Wallet-isolated persistence for the latest balance snapshot.
///
/// Every entry is scoped by [walletId] so balances can never leak across
/// wallets. The id comes from `WalletIdService` (a random UUID v4, rotated on
/// wallet delete/import) — see `wallet_id_service.dart` for the generation
/// and rotation contract.
abstract class BalanceSnapshotStore {
  /// Persists [snapshot] as the latest balances for [walletId], replacing any
  /// previous snapshot for that wallet. Best-effort: a failed write must never
  /// abort a sync.
  Future<void> save(String walletId, BalanceSnapshot snapshot);

  /// Returns the last persisted snapshot for [walletId], or null when none
  /// exists (fresh wallet, or after a clear) or the stored entry is corrupt.
  Future<BalanceSnapshot?> load(String walletId);

  /// Removes the snapshot for a single [walletId].
  Future<void> clear(String walletId);

  /// Removes every persisted balance snapshot, regardless of wallet. Used by
  /// the wallet delete/import cleanup hooks to guarantee no prior wallet's
  /// balances survive into a newly created or imported wallet under the
  /// single-wallet-at-a-time invariant.
  Future<void> clearAll();
}
