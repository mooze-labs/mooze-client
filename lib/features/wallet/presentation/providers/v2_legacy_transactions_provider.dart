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
/// - V2's `TransactionDirection.internal` maps to legacy `unknown`
///   because legacy only has send/receive/swap/submarine/redeposit.
///   Internal transfers (Breez fee txs etc.) render as "unknown".
/// - Legacy swap-pair fields (fromAsset/toAsset/sentAmount/
///   receivedAmount) are left null. V2 represents swap legs as
///   separate transactions; a future Stage 3 step will reintroduce
///   one-row swap rendering by joining via `swap_audit`.
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
    v2.TransactionDirection.internal => legacy.TransactionType.unknown,
  };

  final status = switch (t.status) {
    v2.TransactionStatus.pending => legacy.TransactionStatus.pending,
    v2.TransactionStatus.confirmed => legacy.TransactionStatus.confirmed,
    v2.TransactionStatus.failed => legacy.TransactionStatus.failed,
  };

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
  );
}
