import 'package:mooze_mobile/domain/entities/chain.dart' as v2;
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart'
    as legacy;
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Maps one V2 domain [v2.Transaction] to the legacy UI
/// [legacy.Transaction] shape.
///
/// The home list adapter (`v2LegacyTransactionsProvider`) and the
/// service-backed legacy wallet repository share this function, so both
/// paths render the same row for the same V2 transaction.
legacy.Transaction legacyTransactionFromV2(v2.Transaction t) {
  // Peg-in claim / peg-out lockup from Breez surface as
  // `PaymentDetails_Bitcoin`, so `_mapPayment` tags them with
  // `chain: ChainId.bitcoin`. But the asset that actually crossed the
  // user's wallet on those payments is L-BTC (Breez paid out / took in
  // L-BTC at the Liquid side of the swap — only the swap mechanics
  // touched native Bitcoin). Without this remap, the home tx list
  // renders "Recebeu BTC" for a peg-in claim and `swap_unifier` can't
  // pair it with the BDK BTC send (the LBTC bucket stays empty), and
  // `pendingSwapsReconciliationProvider._isReconciled` can't find a
  // matching destination credit (the optimistic "Converting" row
  // never retires). BDK-written rows on chain=bitcoin keep their
  // native (Bitcoin, BTC) classification because their
  // `source == TransactionSource.bdk`.
  final isBreezChainSwapBitcoin =
      t.chain == v2.ChainId.bitcoin && t.source == v2.TransactionSource.breez;

  final Asset asset;
  if (isBreezChainSwapBitcoin) {
    asset = Asset.lbtc;
  } else if (t.chain == v2.ChainId.bitcoin) {
    asset = Asset.btc;
  } else if (t.assetId != null) {
    asset = Asset.fromId(t.assetId!);
  } else {
    // Liquid + Lightning entries with no assetId == L-BTC pool.
    asset = Asset.lbtc;
  }

  final blockchain = isBreezChainSwapBitcoin
      ? Blockchain.liquid
      : switch (t.chain) {
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
  final sentAmount =
      t.sentAmountSat == null ? null : BigInt.from(t.sentAmountSat!);
  final receivedAmount =
      t.receivedAmountSat == null ? null : BigInt.from(t.receivedAmountSat!);

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
    feesSat: BigInt.from(t.feeSat),
  );
}
