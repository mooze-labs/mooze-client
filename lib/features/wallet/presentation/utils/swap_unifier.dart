import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum SwapDirection { pegIn, pegOut }

/// Collapses the multiple raw entries a Breez chain-swap leaves in the
/// transaction stream (Breez anchor + BDK BTC leg + LWK/Breez LBTC leg +
/// duplicate cross-chain views) into a single [TransactionType.swap]
/// row.
///
/// The V2 stream path (`v2LegacyTransactionsProvider`) lands here
/// because it doesn't go through the legacy
/// `WalletRepositoryImpl._identifyInternalSwapsStatic` pairing pass.
/// The two paths are intentionally separate — this one keys off the
/// Breez chain-swap anchor id when available and falls back to
/// amount/time pairing only when no anchor is found.
///
/// Performance: the matcher first scans `input` once to (a) decide
/// whether any peg-shaped row is present (fast return when not) and
/// (b) bucket transactions by `(chain, asset, type)`. Per-anchor leg
/// lookups then iterate only the 4 relevant buckets instead of the
/// whole list, dropping anchor pairing from O(n²) to roughly O(n).
List<Transaction> unifyPegSwaps(List<Transaction> input) {
  if (input.isEmpty) return input;

  // Self-timing so the cost shows up regardless of which isolate this
  // ran on. The `BootTracer` stopwatch is per-isolate (only started on
  // the UI isolate) so timestamps from a `compute` isolate would be
  // bogus — we emit a stand-alone debugPrint with the delta in ms.
  final sw = Stopwatch()..start();

  // Bucket on the original list while also checking the cheap
  // existence predicates. We do both passes inline so we only walk
  // `input` once before deciding whether to bail out.
  final _Indexed indexed = _indexAndProbe(input);

  // Fast path: nothing peg-shaped at all — skip dedupe, skip bucket
  // work, skip the final sort. The vast majority of stream ticks for
  // an unswap'd wallet land here.
  if (!indexed.hasAnchorCandidate && !indexed.hasPairableSend) {
    final ms = sw.elapsedMilliseconds;
    if (ms >= 2) {
      debugPrint('[MARK unifier.fastpath n=${input.length} dur_ms=$ms]');
    }
    return input;
  }

  final deduped = _dedupeByIdPreferLiquid(input, indexed);

  // Re-bucket from the deduped list — the dedupe pass can drop a
  // mirrored bitcoin-view row, which would otherwise produce a stale
  // bucket entry pointing at the dropped instance.
  final buckets = _bucketize(deduped);

  final consumed = <String>{};
  final unified = <Transaction>[];

  for (final tx in deduped) {
    if (consumed.contains(tx.id)) continue;
    if (!_isBreezChainSwapAnchor(tx)) continue;

    final pair = _pairLegsForAnchor(tx, buckets, consumed);
    if (pair == null) continue;

    consumed.add(tx.id);
    if (pair.btcLeg != null) consumed.add(pair.btcLeg!.id);
    if (pair.lbtcLeg != null) consumed.add(pair.lbtcLeg!.id);
    unified.add(_buildAnchoredSwap(tx, pair));
  }

  // Fallback path: walk only the send-side buckets, not the whole list.
  for (final tx in buckets.btcSends) {
    if (consumed.contains(tx.id)) continue;
    final cp = _findFallbackCounterpart(tx, buckets.lbtcReceives, consumed);
    if (cp == null) continue;
    consumed.add(tx.id);
    consumed.add(cp.id);
    unified.add(_buildFallbackSwap(tx, cp));
  }
  for (final tx in buckets.lbtcSends) {
    if (consumed.contains(tx.id)) continue;
    final cp = _findFallbackCounterpart(tx, buckets.btcReceives, consumed);
    if (cp == null) continue;
    consumed.add(tx.id);
    consumed.add(cp.id);
    unified.add(_buildFallbackSwap(tx, cp));
  }

  for (final send in buckets.btcSends) {
    if (consumed.contains(send.id)) continue;
    final refund = _findRefundCounterpart(send, buckets.btcReceives, consumed);
    if (refund == null) continue;
    final row = _buildRefundedSwap(send, refund);
    if (row == null) continue;
    consumed.add(send.id);
    consumed.add(refund.id);
    unified.add(row);
  }

  // No work landed — return the input list unchanged (callers can rely
  // on reference equality to short-circuit downstream rebuilds).
  if (consumed.isEmpty && unified.isEmpty && deduped.length == input.length) {
    final ms = sw.elapsedMilliseconds;
    if (ms >= 2) {
      debugPrint('[MARK unifier.noop n=${input.length} dur_ms=$ms]');
    }
    return input;
  }

  final result = <Transaction>[
    for (final tx in deduped)
      if (!consumed.contains(tx.id)) tx,
    ...unified,
  ];

  // Skip the sort if no swap was inserted — `deduped` preserves the
  // original ordering, so the result is already in input order.
  if (unified.isNotEmpty) {
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  final ms = sw.elapsedMilliseconds;
  debugPrint('[MARK unifier.done '
      'n_in=${input.length} n_out=${result.length} '
      'consumed=${consumed.length} merged=${unified.length} dur_ms=$ms]');
  return result;
}

/// Convenience getters that expose the unified swap row in the shape
/// requested by transaction-detail consumers (peg-in/peg-out, per-rail
/// txid lists, send/receive addresses).
extension SwapTransactionX on Transaction {
  bool get isPegSwap =>
      type == TransactionType.swap &&
      ((fromAsset == Asset.btc && toAsset == Asset.lbtc) ||
          (fromAsset == Asset.lbtc && toAsset == Asset.btc)) &&
      sendBlockchain != null &&
      receiveBlockchain != null &&
      sendBlockchain != receiveBlockchain;

  SwapDirection? get swapDirection {
    if (!isPegSwap) return null;
    return fromAsset == Asset.btc ? SwapDirection.pegIn : SwapDirection.pegOut;
  }

  List<String> get btcTransactionIds {
    if (!isPegSwap) return const [];
    final direction = swapDirection;
    final id = direction == SwapDirection.pegIn ? sendTxId : receiveTxId;
    return id == null ? const [] : [id];
  }

  List<String> get lbtcTransactionIds {
    if (!isPegSwap) return const [];
    final direction = swapDirection;
    final id = direction == SwapDirection.pegIn ? receiveTxId : sendTxId;
    return id == null ? const [] : [id];
  }
}

// ─────────────────────────────────────────── internals

class _Buckets {
  final List<Transaction> btcSends;
  final List<Transaction> btcReceives;
  final List<Transaction> lbtcSends;
  final List<Transaction> lbtcReceives;
  const _Buckets({
    required this.btcSends,
    required this.btcReceives,
    required this.lbtcSends,
    required this.lbtcReceives,
  });
}

class _Indexed {
  final bool hasAnchorCandidate;
  final bool hasPairableSend;
  final bool hasDuplicateIds;
  const _Indexed({
    required this.hasAnchorCandidate,
    required this.hasPairableSend,
    required this.hasDuplicateIds,
  });
}

/// Single linear scan that decides whether `input` contains anything
/// peg-shaped at all — so we can bail out cheaply on the common case
/// of a stream tick from a wallet with no Breez chain swaps.
///
/// Threshold is low (1k sats) so the unifier wakes up for refunded
/// peg detection too, where the lockup amount can be well under the
/// 25k chain-swap minimum (e.g. the 3k refund-test path).
_Indexed _indexAndProbe(List<Transaction> input) {
  final minAmount = BigInt.from(1000);
  bool anchor = false;
  bool send = false;
  bool dup = false;
  final seenIds = <String>{};

  for (final tx in input) {
    if (!seenIds.add(tx.id)) dup = true;

    if (!anchor && _isBreezChainSwapAnchor(tx)) anchor = true;

    if (!send &&
        tx.type == TransactionType.send &&
        tx.amount >= minAmount &&
        (tx.asset == Asset.btc || tx.asset == Asset.lbtc) &&
        (tx.blockchain == Blockchain.bitcoin ||
            tx.blockchain == Blockchain.liquid)) {
      send = true;
    }

    if (anchor && send && dup) break; // nothing left to discover
  }

  return _Indexed(
    hasAnchorCandidate: anchor,
    hasPairableSend: send,
    hasDuplicateIds: dup,
  );
}

List<Transaction> _dedupeByIdPreferLiquid(
  List<Transaction> input,
  _Indexed probe,
) {
  // Skip the dedupe pass entirely when the probe didn't see any
  // duplicate ids. The deduped list is identical to `input` in that
  // case, and skipping avoids both the map allocation and the final
  // rebuild iteration.
  if (!probe.hasDuplicateIds) return input;

  final byId = <String, Transaction>{};
  final order = <String>[];
  for (final tx in input) {
    final existing = byId[tx.id];
    if (existing == null) {
      byId[tx.id] = tx;
      order.add(tx.id);
      continue;
    }
    // Same id present on liquid + bitcoin → keep the Liquid view
    // (the real LBTC claim) and drop the bitcoin mirror.
    final preferIncoming = existing.blockchain == Blockchain.bitcoin &&
        tx.blockchain == Blockchain.liquid;
    if (preferIncoming) byId[tx.id] = tx;
  }
  return [for (final id in order) byId[id]!];
}

_Buckets _bucketize(List<Transaction> input) {
  final btcSends = <Transaction>[];
  final btcReceives = <Transaction>[];
  final lbtcSends = <Transaction>[];
  final lbtcReceives = <Transaction>[];
  for (final tx in input) {
    if (tx.blockchain == Blockchain.bitcoin && tx.asset == Asset.btc) {
      if (tx.type == TransactionType.send) {
        btcSends.add(tx);
      } else if (tx.type == TransactionType.receive) {
        btcReceives.add(tx);
      }
    } else if (tx.blockchain == Blockchain.liquid && tx.asset == Asset.lbtc) {
      if (tx.type == TransactionType.send) {
        lbtcSends.add(tx);
      } else if (tx.type == TransactionType.receive) {
        lbtcReceives.add(tx);
      }
    }
  }
  return _Buckets(
    btcSends: btcSends,
    btcReceives: btcReceives,
    lbtcSends: lbtcSends,
    lbtcReceives: lbtcReceives,
  );
}

bool _isBreezChainSwapAnchor(Transaction tx) {
  // Breez emits the chain-swap row with the swap id (short opaque
  // string like "wCaunaTNZaHv") until the on-chain claim is observed;
  // afterwards the id flips to the 64-char hex claim txid. Anchors
  // are only meaningful on the on-chain rails and stay above the
  // Boltz chain-swap minimum (~25k sats).
  final id = tx.id;
  if (id.isEmpty) return false;
  if (id.length > 32) return false;
  if (id.length == 64 && _isHexLower(id)) return false;
  if (tx.blockchain != Blockchain.bitcoin &&
      tx.blockchain != Blockchain.liquid) {
    return false;
  }
  if (tx.type == TransactionType.swap) return false;
  if (tx.amount < BigInt.from(25000)) return false;
  return true;
}

bool _isHexLower(String s) {
  for (final code in s.codeUnits) {
    final isDigit = code >= 0x30 && code <= 0x39;
    final isLowerHex = code >= 0x61 && code <= 0x66;
    if (!isDigit && !isLowerHex) return false;
  }
  return true;
}

class _SwapLegs {
  final Transaction? btcLeg;
  final Transaction? lbtcLeg;
  final SwapDirection direction;
  const _SwapLegs({
    required this.btcLeg,
    required this.lbtcLeg,
    required this.direction,
  });
}

_SwapLegs? _pairLegsForAnchor(
  Transaction anchor,
  _Buckets buckets,
  Set<String> consumed,
) {
  // Fallback path for HISTORICAL pegs only — fresh pegs are merged
  // upstream by `_mergeBreezPegSwaps` using exact `swap_lockup_tx_id`
  // linkage. 30 min is tight enough to keep an unrelated BTC
  // withdrawal hours later out of the match (the old 12 h window
  // mispaired a same-amount saque with a peg-in claim because they
  // happened on the same day).
  const horizon = Duration(minutes: 30);
  // Chain-swap fees usually land below 3% but can reach ~10% on
  // small amounts after lockup + claim fees + Breez service fee.
  const tolerance = 0.10;

  final btcSend =
      _firstMatchInBucket(anchor, buckets.btcSends, consumed, horizon, tolerance);
  final lbtcReceive = _firstMatchInBucket(
      anchor, buckets.lbtcReceives, consumed, horizon, tolerance);
  if (btcSend != null && lbtcReceive != null) {
    return _SwapLegs(
      btcLeg: btcSend,
      lbtcLeg: lbtcReceive,
      direction: SwapDirection.pegIn,
    );
  }

  final lbtcSend = _firstMatchInBucket(
      anchor, buckets.lbtcSends, consumed, horizon, tolerance);
  final btcReceive = _firstMatchInBucket(
      anchor, buckets.btcReceives, consumed, horizon, tolerance);
  if (lbtcSend != null && btcReceive != null) {
    return _SwapLegs(
      btcLeg: btcReceive,
      lbtcLeg: lbtcSend,
      direction: SwapDirection.pegOut,
    );
  }

  // Partial pairing — surface a unified row anyway so the anchor
  // doesn't appear as a bare "BTC receive of N sats pending" row
  // while the second leg is still propagating.
  if (btcSend != null) {
    return _SwapLegs(
      btcLeg: btcSend,
      lbtcLeg: null,
      direction: SwapDirection.pegIn,
    );
  }
  if (lbtcReceive != null) {
    return _SwapLegs(
      btcLeg: null,
      lbtcLeg: lbtcReceive,
      direction: SwapDirection.pegIn,
    );
  }
  if (lbtcSend != null) {
    return _SwapLegs(
      btcLeg: null,
      lbtcLeg: lbtcSend,
      direction: SwapDirection.pegOut,
    );
  }
  if (btcReceive != null) {
    return _SwapLegs(
      btcLeg: btcReceive,
      lbtcLeg: null,
      direction: SwapDirection.pegOut,
    );
  }
  return null;
}

Transaction? _firstMatchInBucket(
  Transaction anchor,
  List<Transaction> bucket,
  Set<String> consumed,
  Duration horizon,
  double tolerance,
) {
  for (final cand in bucket) {
    if (cand.id == anchor.id || consumed.contains(cand.id)) continue;
    if (cand.createdAt.difference(anchor.createdAt).abs() > horizon) continue;
    if (!_amountsApproxMatch(cand.amount, anchor.amount, tolerance)) continue;
    return cand;
  }
  return null;
}

bool _amountsApproxMatch(BigInt a, BigInt b, double tolerance) {
  if (a == BigInt.zero || b == BigInt.zero) return false;
  final larger = a > b ? a : b;
  final smaller = a > b ? b : a;
  final diff = larger - smaller;
  return diff.toDouble() / larger.toDouble() <= tolerance;
}

Transaction _buildAnchoredSwap(Transaction anchor, _SwapLegs pair) {
  final isPegIn = pair.direction == SwapDirection.pegIn;
  final sendLeg = isPegIn ? pair.btcLeg : pair.lbtcLeg;
  final receiveLeg = isPegIn ? pair.lbtcLeg : pair.btcLeg;

  final sentAmount = sendLeg?.amount ?? anchor.amount;
  final receivedAmount = receiveLeg?.amount ?? anchor.amount;

  var earliest = anchor.createdAt;
  final btcLeg = pair.btcLeg;
  final lbtcLeg = pair.lbtcLeg;
  if (btcLeg != null && btcLeg.createdAt.isBefore(earliest)) {
    earliest = btcLeg.createdAt;
  }
  if (lbtcLeg != null && lbtcLeg.createdAt.isBefore(earliest)) {
    earliest = lbtcLeg.createdAt;
  }

  return Transaction(
    id: anchor.id,
    amount: receivedAmount,
    blockchain: isPegIn ? Blockchain.liquid : Blockchain.bitcoin,
    asset: isPegIn ? Asset.lbtc : Asset.btc,
    type: TransactionType.swap,
    status: _statusFromLegs(anchor, pair),
    createdAt: earliest,
    fromAsset: isPegIn ? Asset.btc : Asset.lbtc,
    toAsset: isPegIn ? Asset.lbtc : Asset.btc,
    sentAmount: sentAmount,
    receivedAmount: receivedAmount,
    sendTxId: sendLeg?.id,
    receiveTxId: receiveLeg?.id,
    sendBlockchain: isPegIn ? Blockchain.bitcoin : Blockchain.liquid,
    receiveBlockchain: isPegIn ? Blockchain.liquid : Blockchain.bitcoin,
    destination: receiveLeg?.destination ?? anchor.destination,
    blockchainUrl: anchor.blockchainUrl,
    preimage: anchor.preimage,
    feesSat: anchor.feesSat,
  );
}

TransactionStatus _statusFromLegs(Transaction anchor, _SwapLegs pair) {
  if (anchor.status == TransactionStatus.refundable) {
    return TransactionStatus.refundable;
  }
  if (anchor.status == TransactionStatus.failed) {
    return TransactionStatus.failed;
  }
  bool isPendingLeg(Transaction? t) =>
      t == null || t.status == TransactionStatus.pending;
  if (isPendingLeg(pair.btcLeg) || isPendingLeg(pair.lbtcLeg)) {
    return TransactionStatus.pending;
  }
  return TransactionStatus.confirmed;
}

Transaction? _findFallbackCounterpart(
  Transaction sendTx,
  List<Transaction> receiveBucket,
  Set<String> consumed,
) {
  // Mirrors the legacy `_identifyInternalSwapsStatic` heuristics so
  // the V2 path produces the same unified rows for historical pegs
  // that pre-date the swap-link fields. 30 min keeps unrelated
  // sends/receives on the same day from being paired by accident.
  final minAmount = BigInt.from(25000);
  const horizon = Duration(minutes: 30);
  if (sendTx.amount < minAmount) return null;

  // Precompute the ±1% / ±10% acceptance window once per call.
  final minExpected = (sendTx.amount * BigInt.from(90)) ~/ BigInt.from(100);
  final maxExpected = (sendTx.amount * BigInt.from(101)) ~/ BigInt.from(100);

  for (final cand in receiveBucket) {
    if (cand.id == sendTx.id || consumed.contains(cand.id)) continue;
    if (cand.amount < minExpected || cand.amount > maxExpected) continue;
    if (cand.createdAt.difference(sendTx.createdAt).abs() > horizon) continue;
    return cand;
  }
  return null;
}

Transaction _buildFallbackSwap(Transaction send, Transaction receive) {
  final earliest = send.createdAt.isBefore(receive.createdAt)
      ? send.createdAt
      : receive.createdAt;
  return Transaction(
    id: '${send.id}_${receive.id}_swap',
    amount: receive.amount,
    blockchain: receive.blockchain,
    asset: receive.asset,
    type: TransactionType.swap,
    status: send.status == TransactionStatus.confirmed &&
            receive.status == TransactionStatus.confirmed
        ? TransactionStatus.confirmed
        : TransactionStatus.pending,
    createdAt: earliest,
    fromAsset: send.asset,
    toAsset: receive.asset,
    sentAmount: send.amount,
    receivedAmount: receive.amount,
    sendTxId: send.id,
    receiveTxId: receive.id,
    sendBlockchain: send.blockchain,
    receiveBlockchain: receive.blockchain,
    destination: receive.destination,
    feesSat: _sumLegFees(send.feesSat, receive.feesSat),
  );
}

BigInt? _sumLegFees(BigInt? a, BigInt? b) {
  if (a == null && b == null) return null;
  return (a ?? BigInt.zero) + (b ?? BigInt.zero);
}

Transaction? _findRefundCounterpart(
  Transaction send,
  List<Transaction> receiveBucket,
  Set<String> consumed,
) {
  if (send.blockchain != Blockchain.bitcoin || send.asset != Asset.btc) {
    return null;
  }
  // Threshold mirrors the chain-swap minimum the SDK enforces; below
  // it, the row is more likely a legitimate small payment than a
  // peg attempt. Set deliberately low (1k sats, not 25k like the
  // happy-path matcher) so the refund test case — a 3k-sat lockup
  // returning ~2.8k — is still detected.
  if (send.amount < BigInt.from(1000)) return null;
  const window = Duration(hours: 24);

  for (final cand in receiveBucket) {
    if (cand.id == send.id || consumed.contains(cand.id)) continue;
    if (cand.blockchain != Blockchain.bitcoin || cand.asset != Asset.btc) {
      continue;
    }
    final delta = cand.createdAt.difference(send.createdAt);
    if (delta < Duration.zero || delta > window) continue;
    // Receive must be *strictly less* than send (refund fee taken)
    // but not implausibly less (drop below ~0.5 and the pair is
    // probably unrelated, not a refund).
    final ratio = cand.amount.toDouble() / send.amount.toDouble();
    if (ratio < 0.50 || ratio >= 1.0) continue;
    return cand;
  }
  return null;
}


Transaction? _buildRefundedSwap(Transaction send, Transaction receive) {
  if (send.blockchain != Blockchain.bitcoin ||
      send.asset != Asset.btc ||
      receive.blockchain != Blockchain.bitcoin ||
      receive.asset != Asset.btc) {
    return null;
  }
  final earliest = send.createdAt.isBefore(receive.createdAt)
      ? send.createdAt
      : receive.createdAt;
  return Transaction(
    id: '${send.id}_${receive.id}_refund',
    amount: receive.amount,
    blockchain: Blockchain.bitcoin,
    asset: Asset.btc,
    type: TransactionType.swap,
    status: send.status == TransactionStatus.confirmed &&
            receive.status == TransactionStatus.confirmed
        ? TransactionStatus.confirmed
        : TransactionStatus.pending,
    createdAt: earliest,
    // Same-asset on both sides is the signal the UI uses to render
    // this row as a refund instead of a successful swap. The V2
    // legacy `Transaction` doesn't have a dedicated refund flag, so
    fromAsset: Asset.btc,
    toAsset: Asset.btc,
    sentAmount: send.amount,
    receivedAmount: receive.amount,
    sendTxId: send.id,
    receiveTxId: receive.id,
    sendBlockchain: Blockchain.bitcoin,
    receiveBlockchain: Blockchain.bitcoin,
    destination: receive.destination,
    feesSat: _sumLegFees(send.feesSat, receive.feesSat),
  );
}
