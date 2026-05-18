import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart' as v2;
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart'
    as legacy;
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Bridges the V2 `walletRepository.watchTransactions()` stream to the
/// legacy `Transaction` shape that `TransactionList`, `transaction history
/// screen`, and the tx-detail screen still render against.
///
/// This file is intentionally narrow: it adapts ONE direction (V2 → UI)
/// for ONE piece of rendering surface that hasn't yet been ported to
/// consume V2 `Transaction` directly. It is NOT a hybrid contract
/// bridge — there is no path from legacy back into V2, and writes never
/// flow through here. Drop this file once `transaction_list.dart` /
/// `transaction_history_screen.dart` consume V2 entities natively.
///
/// Mapping notes:
/// - Asset is resolved by `assetId` for Liquid txs, defaults to L-BTC
///   for assetId-less Liquid/Lightning entries (matches the unified
///   L2 balance model: Lightning is a rail on top of L-BTC).
/// - V2's `TransactionDirection.selfTransfer` maps to the legacy
///   `TransactionType.redeposit` — the home transaction list renders
///   that as "Redeposit <TICKER>". `amountSat` is the fee.
/// - V2's `TransactionDirection.swap` (added Phase 2b) maps to
///   `TransactionType.swap` and propagates the four swap-pair fields
///   (`fromAsset`/`toAsset`/`sentAmount`/`receivedAmount`) so the home
///   list's existing swap-row rendering (`HomeTransactionItem.
///   _buildSwapSubtitle`, `_buildSwapIcon`) lights up. Single-tx
///   swaps only — cross-tx pairing (e.g. BTC L1 ↔ Liquid LBTC peg)
///   is deferred to a future iteration.
/// - V2's `TransactionDirection.internal` still maps to legacy
///   `unknown` for Breez fee adjustments / unresolvable LWK kinds /
///   issuance/burn/reissuance.
final v2LegacyTransactionsProvider =
    StreamProvider<List<legacy.Transaction>>((ref) async* {
  final repo = await ref.watch(walletRepositoryProvider.future);
  await for (final txs in repo.watchTransactions()) {
    yield txs.map(_v2ToLegacy).toList();
  }
});

legacy.Transaction _v2ToLegacy(v2.Transaction t) {
  final Asset asset;
  if (t.chain == v2.ChainId.bitcoin) {
    asset = Asset.btc;
  } else if (t.assetId != null) {
    asset = Asset.fromId(t.assetId!);
  } else {
    // Liquid + Lightning entries with no assetId == L-BTC pool.
    asset = Asset.lbtc;
  }

  final blockchain = switch (t.chain) {
    v2.ChainId.bitcoin => Blockchain.bitcoin,
    v2.ChainId.liquid => Blockchain.liquid,
    v2.ChainId.lightning => Blockchain.lightning,
    // `aggregate` is a synthetic chain used by sync outcomes — it
    // should never appear on a persisted transaction. Default to
    // bitcoin for safety; if we hit this in practice it's a bug.
    v2.ChainId.aggregate => Blockchain.bitcoin,
  };

  final type = switch (t.direction) {
    v2.TransactionDirection.incoming => legacy.TransactionType.receive,
    v2.TransactionDirection.outgoing => legacy.TransactionType.send,
    v2.TransactionDirection.selfTransfer => legacy.TransactionType.redeposit,
    v2.TransactionDirection.swap => legacy.TransactionType.swap,
    v2.TransactionDirection.internal => legacy.TransactionType.unknown,
  };

  final status = switch (t.status) {
    v2.TransactionStatus.pending => legacy.TransactionStatus.pending,
    v2.TransactionStatus.confirmed => legacy.TransactionStatus.confirmed,
    v2.TransactionStatus.failed => legacy.TransactionStatus.failed,
  };

  // Swap-pair pass-through. `Asset.fromId` throws on unknown asset ids
  // (e.g., a Liquid asset the wallet doesn't recognise); the
  // try/catch keeps the row renderable as a generic swap rather than
  // failing the whole adapter.
  Asset? fromAsset;
  Asset? toAsset;
  if (t.fromAssetId != null) {
    try {
      fromAsset = Asset.fromId(t.fromAssetId!);
    } catch (_) {/* unknown asset id — leave null */}
  }
  if (t.toAssetId != null) {
    try {
      toAsset = Asset.fromId(t.toAssetId!);
    } catch (_) {/* unknown asset id — leave null */}
  }
  final sentAmount = t.sentAmountSat == null
      ? null
      : BigInt.from(t.sentAmountSat!);
  final receivedAmount = t.receivedAmountSat == null
      ? null
      : BigInt.from(t.receivedAmountSat!);

  return legacy.Transaction(
    id: t.id,
    amount: BigInt.from(t.amountSat),
    blockchain: blockchain,
    asset: asset,
    type: type,
    status: status,
    createdAt: t.timestamp,
    destination: t.address,
    confirmationHeight: null,
    fromAsset: fromAsset,
    toAsset: toAsset,
    sentAmount: sentAmount,
    receivedAmount: receivedAmount,
  );
}
