import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Pure, dependency-free derivation of an asset's activity metrics from the
/// wallet's transaction history. Lives in the domain layer so it can be
/// exhaustively unit-tested without Flutter, Riverpod, or any data source.
///
/// All aggregation is read-only over the already-unified legacy
/// [Transaction] list (peg swaps are collapsed upstream by
/// `v2LegacyTransactionsProvider`).
abstract final class AssetActivityCalculator {
  /// A transaction carries clean per-leg swap semantics only when all four
  /// swap-pair fields are populated. Peg-ins/outs and same-tx swaps satisfy
  /// this; a plain send/receive does not.
  static bool _isSwapShaped(Transaction tx) =>
      tx.fromAsset != null &&
      tx.toAsset != null &&
      tx.sentAmount != null &&
      tx.receivedAmount != null;

  /// Returns the subset of [transactions] that involve [asset] — either as
  /// the headline asset (sends/receives/redeposits) or as one leg of a
  /// swap/peg. Order is preserved.
  static List<Transaction> filterForAsset(
    Asset asset,
    List<Transaction> transactions,
  ) {
    return [
      for (final tx in transactions)
        if (tx.asset == asset ||
            (_isSwapShaped(tx) &&
                (tx.fromAsset == asset || tx.toAsset == asset)))
          tx,
    ];
  }

  /// Computes the [AssetActivitySummary] for [asset] over [transactions].
  ///
  /// Timeline bounds ([AssetActivitySummary.firstActivity] /
  /// [AssetActivitySummary.lastActivity]) and the transaction count include
  /// every relevant row regardless of status. Monetary aggregates exclude
  /// `failed` rows — they never moved value — and rows that lack clean
  /// send/receive semantics for the asset (internal redeposits, unclassified
  /// entries, swap-shaped rows missing a leg).
  static AssetActivitySummary summarize({
    required Asset asset,
    required List<Transaction> transactions,
  }) {
    final relevant = filterForAsset(asset, transactions);
    if (relevant.isEmpty) return AssetActivitySummary.empty(asset);

    var totalReceived = BigInt.zero;
    var totalSent = BigInt.zero;
    var largestReceive = BigInt.zero;
    var largestSend = BigInt.zero;
    DateTime? firstActivity;
    DateTime? lastActivity;

    void addReceive(BigInt value) {
      totalReceived += value;
      if (value > largestReceive) largestReceive = value;
    }

    void addSend(BigInt value) {
      totalSent += value;
      if (value > largestSend) largestSend = value;
    }

    for (final tx in relevant) {
      final created = tx.createdAt;
      if (firstActivity == null || created.isBefore(firstActivity)) {
        firstActivity = created;
      }
      if (lastActivity == null || created.isAfter(lastActivity)) {
        lastActivity = created;
      }

      if (tx.status == TransactionStatus.failed) continue;

      if (_isSwapShaped(tx)) {
        // A swap can touch this asset on one or both legs (a same-asset
        // refund peg touches both). Credit/debit whichever leg matches.
        if (tx.toAsset == asset) addReceive(tx.receivedAmount!);
        if (tx.fromAsset == asset) addSend(tx.sentAmount!);
        continue;
      }

      switch (tx.type) {
        case TransactionType.receive:
          addReceive(tx.amount);
        case TransactionType.send:
          addSend(tx.amount);
        case TransactionType.swap:
        case TransactionType.submarine:
        case TransactionType.redeposit:
        case TransactionType.unknown:
          // No clean single-asset received/sent semantics: redeposit is an
          // internal fee-only move, unknown is unclassified, and any swap/
          // submarine reaching here is missing its pair fields. Counted in
          // the activity list + timeline, excluded from value aggregates.
          break;
      }
    }

    return AssetActivitySummary(
      asset: asset,
      transactionCount: relevant.length,
      totalReceived: totalReceived,
      totalSent: totalSent,
      totalVolume: totalReceived + totalSent,
      largestReceive: largestReceive,
      largestSend: largestSend,
      firstActivity: firstActivity,
      lastActivity: lastActivity,
    );
  }
}
