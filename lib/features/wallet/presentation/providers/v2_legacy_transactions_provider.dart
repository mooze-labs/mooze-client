import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart' as v2;
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart'
    as legacy;
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/utils/swap_unifier.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
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
/// Lists at or above this size are adapted + unified in a background
/// isolate via `compute`. Below the threshold, the work runs inline.
///
/// Threshold calibration (2026-05-24): traces consistently showed that
/// `compute()` runs of 225-tx lists took ~2200 ms wall-clock with the
/// actual `unifier.done` reporting `dur_ms=4`. The 2196 ms delta is
/// PURE OVERHEAD — spawning a fresh isolate plus serializing 225
/// `Transaction` objects through the `SendPort` (an O(n) deep-copy
/// that runs on the UI isolate, blocking the heartbeat). Inline,
/// the same workload finishes in single-digit ms.
///
/// At 1500, even larger wallets adapt+unify on the UI thread in well
/// under one frame (16ms budget) thanks to `_adaptAndUnify` being
/// pure transforms over already-decoded lists. The isolate path is
/// reserved for genuinely huge tx tables where the math would visibly
/// stutter the frame; for everyday wallets the inline path is faster
/// AND smoother.
///
/// The first emission after PIN entry runs the full
/// `SELECT * FROM transactions` against sqlite on the UI isolate
/// (see `TransactionStoreImpl.watch`) — for wallets with non-trivial
/// history, processing that list synchronously was blocking the UI
/// thread long enough to be perceived as a freeze, but the unifier
/// itself isn't the bottleneck anymore.
const _isolateThreshold = 1500;

final v2LegacyTransactionsProvider =
    StreamProvider<List<legacy.Transaction>>((ref) {
  // We use a manual StreamController instead of `async*` so we can
  // implement drop-intermediate semantics: while a compute() is in
  // flight, additional upstream emissions don't queue a new compute
  // each — they just stash themselves as "latest pending input". When
  // the in-flight compute finishes, if the latest pending differs
  // from what we just processed, we kick off one more compute. This
  // collapses a storm of N upstream emissions during a sync into at
  // most 2 computes (the one in flight when the storm started + one
  // for the final state).
  final controller = StreamController<List<legacy.Transaction>>();

  // Cache state — same shape as before (fingerprint + length tuple +
  // last result).
  int? lastFingerprint;
  int? lastLength;
  List<legacy.Transaction>? lastResult;
  var emissionSeq = 0;

  List<v2.Transaction>? pending;
  bool processing = false;
  bool cancelled = false;

  Future<void> drain() async {
    if (processing) return;
    processing = true;
    try {
      while (!cancelled && pending != null) {
        final txs = pending!;
        pending = null;
        emissionSeq += 1;
        final seq = emissionSeq;
        BootTracer.mark('v2_legacy_txs.process', {
          'n': seq,
          'len': txs.length,
        });

        final fingerprint = _fingerprint(txs);
        final hit = fingerprint == lastFingerprint &&
            txs.length == lastLength &&
            lastResult != null;
        if (hit) {
          BootTracer.mark('v2_legacy_txs.cache_hit', {
            'n': seq,
            'len': txs.length,
          });
          if (!controller.isClosed) controller.add(lastResult!);
          continue;
        }
        if (txs.isEmpty) {
          BootTracer.mark('v2_legacy_txs.empty_emit', {
            'n': seq,
            'prior_len': lastLength,
          });
        }

        final List<legacy.Transaction> result;
        if (txs.length >= _isolateThreshold) {
          result = await BootTracer.measureAsync(
            'v2_legacy_txs.compute(n=$seq,len=${txs.length})',
            () => compute(_adaptAndUnify, txs),
          );
        } else {
          BootTracer.mark('v2_legacy_txs.inline.before', {
            'n': seq,
            'len': txs.length,
          });
          final tAdapt = DateTime.now();
          final adapted = txs.map(_v2ToLegacy).toList(growable: false);
          final adaptMs = DateTime.now().difference(tAdapt).inMilliseconds;
          // Peg-swap merge MUST run inline too — same pre-unifier
          // pass `_adaptAndUnify` does on the isolate path. Without
          // this, wallets under [_isolateThreshold] (~every real
          // user) skipped the exact-id merge and saw peg-out + BDK
          // claim as two separate rows.
          final tMerge = DateTime.now();
          final pegMerged = _mergeBreezPegSwaps(txs, adapted);
          final mergeMs = DateTime.now().difference(tMerge).inMilliseconds;
          final tUnify = DateTime.now();
          result = unifyPegSwaps(pegMerged);
          final unifyMs = DateTime.now().difference(tUnify).inMilliseconds;
          BootTracer.mark('v2_legacy_txs.inline.after', {
            'n': seq,
            'adapt_ms': adaptMs,
            'merge_ms': mergeMs,
            'unify_ms': unifyMs,
          });
        }

        lastFingerprint = fingerprint;
        lastLength = txs.length;
        lastResult = result;
        BootTracer.mark('v2_legacy_txs.yield', {
          'n': seq,
          'len': result.length,
        });
        if (!controller.isClosed) controller.add(result);
      }
    } finally {
      processing = false;
    }
  }

  StreamSubscription<List<v2.Transaction>>? sub;
  BootTracer.mark('v2_legacy_txs.resolving_repo');
  ref.watch(walletRepositoryProvider.future).then((repo) {
    BootTracer.mark('v2_legacy_txs.repo_resolved');
    if (cancelled) return;
    sub = repo.watchTransactions().listen((txs) {
      // Always overwrite — older pending inputs are stale by definition,
      // we want to process the freshest state. Logging the drop is
      // useful for confirming the optimization is actually firing.
      if (pending != null) {
        BootTracer.mark('v2_legacy_txs.drop_intermediate', {
          'prior_len': pending!.length,
          'new_len': txs.length,
        });
      }
      pending = txs;
      drain();
    });
  });

  ref.onDispose(() async {
    cancelled = true;
    await sub?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Top-level entry point so it can be handed to `compute` (which
/// requires a static / top-level callable). Runs the V2→legacy
/// adaptation and the peg-swap unification in one pass — keeping
/// them together means the isolate sees the data once and the only
/// thing crossing isolates is the input list in and the unified
/// list out.
List<legacy.Transaction> _adaptAndUnify(List<v2.Transaction> input) {
  // 1. Per-row adapt V2 → legacy.
  final adapted = input.map(_v2ToLegacy).toList();

  // 2. Pre-unifier merge: Breez chain-swap rows carry
  //    `swapLockupTxId` + `swapClaimTxId` pointing at the BDK halves
  //    of the same peg. Merging them here (with exact id linkage)
  //    produces a single complete swap row per peg, so the
  //    `unifyPegSwaps` pass doesn't have to guess by amount + time
  //    (the old heuristic mispaired an unrelated BTC withdrawal with
  //    a same-amount peg-in claim that landed within ±10% / ±12 h).
  final pegMerged = _mergeBreezPegSwaps(input, adapted);

  // 3. Collapse legacy peg-shaped rows (historical pegs without the
  //    swap-link fields) via the existing unifier — same behaviour
  //    as before, just with no work to do for fresh pegs that step 2
  //    already merged.
  return unifyPegSwaps(pegMerged);
}

/// Merge Breez chain-swap rows with their BDK counterparts into a
/// single swap row using the exact `swap_lockup_tx_id` /
/// `swap_claim_tx_id` linkage Breez exposes through
/// `PaymentDetails_Bitcoin`. Drops the standalone BDK leg + any
/// duplicate Breez pending/confirmed rows for the same swap.
List<legacy.Transaction> _mergeBreezPegSwaps(
  List<v2.Transaction> v2Input,
  List<legacy.Transaction> adapted,
) {
  // Group Breez chain-swap rows by `swapLockupTxId`. Breez emits a
  // pending row (id = swap_id) followed by a confirmed row
  // (id = claim_txid) for the same peg — both share lockup_txid.
  // Pick the freshest/most-confirmed view; drop the rest.
  final pegByLockup = <String, v2.Transaction>{};
  for (final t in v2Input) {
    final lockup = t.swapLockupTxId;
    if (lockup == null) continue;
    final cur = pegByLockup[lockup];
    if (cur == null) {
      pegByLockup[lockup] = t;
      continue;
    }
    // Prefer confirmed over pending; if tie, prefer the one with the
    // later timestamp (Breez updates the timestamp on the confirmed
    // row to settlement time).
    if (cur.status != v2.TransactionStatus.confirmed &&
        t.status == v2.TransactionStatus.confirmed) {
      pegByLockup[lockup] = t;
    } else if (cur.status == t.status &&
        t.timestamp.isAfter(cur.timestamp)) {
      pegByLockup[lockup] = t;
    }
  }
  if (pegByLockup.isEmpty) return adapted;

  // Index every v2 input by id so we can resolve the BDK
  // counterpart by `lockup_tx_id` (peg-in) / `claim_tx_id` (peg-out).
  final v2ById = <String, v2.Transaction>{};
  for (final t in v2Input) {
    v2ById[t.id] = t;
  }

  // Mark every Breez peg row consumed (we'll emit ONE merged row per
  // group). BDK counterparts are consumed when paired below.
  final consumed = <String>{};
  for (final t in v2Input) {
    if (t.swapLockupTxId != null) consumed.add(t.id);
  }

  final merged = <legacy.Transaction>[];
  for (final peg in pegByLockup.values) {
    final isPegIn = peg.direction == v2.TransactionDirection.incoming;
    // BDK side: peg-in lockup tx is what BDK sent; peg-out claim tx
    // is what BDK receives. Both are referenced explicitly by Breez.
    final bdkId = isPegIn ? peg.swapLockupTxId : peg.swapClaimTxId;
    final bdkV2 = bdkId == null ? null : v2ById[bdkId];
    if (bdkV2 != null) consumed.add(bdkV2.id);
    merged.add(_buildPegSwapRow(peg, bdkV2));
  }

  // Filter adapted rows: drop everything we consumed, keep the rest.
  // Append merged peg rows, then sort timestamp DESC so the home list
  // sees the proper recency order.
  final result = <legacy.Transaction>[
    for (final a in adapted)
      if (!consumed.contains(a.id)) a,
    ...merged,
  ];
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// Build a unified peg-swap [legacy.Transaction] from a Breez chain-
/// swap V2 row + an optional BDK counterpart (matched by exact txid).
///
/// Amount semantics — Breez `Payment.amountSat` is the L-BTC pool
/// delta, EXCLUDING the swap fee (`feesSat`), so for the user's
/// "money out" view we have to add the fee back when L-BTC is the
/// send side. BDK amount is whatever the on-chain tx actually moved
/// (lockup amount on peg-in, claim amount on peg-out).
///
///   Peg-in  (paymentType=receive, isPegIn=true):
///     sent     = BDK lockup amount (BTC the user broadcast)
///     received = Breez amountSat   (L-BTC that landed in the pool)
///
///   Peg-out (paymentType=send, isPegIn=false):
///     sent     = Breez amountSat + feesSat (total L-BTC debited)
///     received = BDK claim amount  (BTC that arrived at the
///                destination — if destination was external this is
///                null and the row renders the send side only)
legacy.Transaction _buildPegSwapRow(
  v2.Transaction peg,
  v2.Transaction? bdk,
) {
  final isPegIn = peg.direction == v2.TransactionDirection.incoming;

  final BigInt? sentAmount;
  final BigInt? receivedAmount;
  if (isPegIn) {
    sentAmount =
        bdk != null ? BigInt.from(bdk.amountSat) : null;
    receivedAmount = BigInt.from(peg.amountSat);
  } else {
    sentAmount = BigInt.from(peg.amountSat + peg.feeSat);
    receivedAmount =
        bdk != null ? BigInt.from(bdk.amountSat) : null;
  }

  // Headline `amount` — what the home row displays prominently.
  // Peg-in: the L-BTC received; peg-out: the BTC sent out of the
  // wallet (which equals `receivedAmount` from the destination POV,
  // or `sentAmount` if the user sent to an external BTC address —
  // we use `receivedAmount` when known so peg-in and peg-out are
  // symmetric and falls back to `sentAmount` when the BDK side
  // hasn't been observed yet).
  final headline = receivedAmount ?? sentAmount ?? BigInt.from(peg.amountSat);

  // Status: confirmed only when BOTH legs are confirmed. The pending
  // optimistic row from `pendingSwapsProvider` retires off this row
  // — keeping it pending while either leg is still propagating
  // matches what the user expects ("not done yet, both sides
  // settling").
  legacy.TransactionStatus mapStatus(v2.TransactionStatus s) =>
      switch (s) {
        v2.TransactionStatus.pending => legacy.TransactionStatus.pending,
        v2.TransactionStatus.confirmed => legacy.TransactionStatus.confirmed,
        v2.TransactionStatus.failed => legacy.TransactionStatus.failed,
      };
  final pegStatus = mapStatus(peg.status);
  final bdkStatus = bdk == null ? null : mapStatus(bdk.status);
  final status = (pegStatus == legacy.TransactionStatus.confirmed &&
          (bdkStatus == null ||
              bdkStatus == legacy.TransactionStatus.confirmed))
      ? legacy.TransactionStatus.confirmed
      : (pegStatus == legacy.TransactionStatus.failed ||
              bdkStatus == legacy.TransactionStatus.failed)
          ? legacy.TransactionStatus.failed
          : legacy.TransactionStatus.pending;

  // Earliest timestamp wins so the row sorts before the standalone
  // BDK leg ever did (the BDK ts is usually the broadcast block ts).
  var earliest = peg.timestamp;
  if (bdk != null && bdk.timestamp.isBefore(earliest)) {
    earliest = bdk.timestamp;
  }

  // Send/receive tx ids. The legacy `sendTxId`/`receiveTxId` fields
  // are what the tx-detail screen reads to render the per-rail
  // explorer links; they're also what
  // `pendingSwapsReconciliationProvider._idsMatch` uses to retire
  // the optimistic peg row.
  //
  // Must always identify the tx on the matching `sendBlockchain` /
  // `receiveBlockchain`. `peg.id` is unsafe here — Breez flips it
  // between the lockup txid, the swap_id (Boltz internal), and the
  // claim txid across the swap lifecycle, so pairing `peg.id` with
  // `sendBlockchain` produced a cross-chain leak for peg-out (a
  // Liquid lockup hash tagged as Bitcoin). `swapLockupTxId` /
  // `swapClaimTxId` are stable across the lifecycle and always
  // belong to the source / destination chain respectively.
  final sendTxId = peg.swapLockupTxId;
  final receiveTxId = peg.swapClaimTxId;

  return legacy.Transaction(
    id: peg.id,
    amount: headline,
    blockchain: isPegIn ? Blockchain.liquid : Blockchain.bitcoin,
    asset: isPegIn ? Asset.lbtc : Asset.btc,
    type: legacy.TransactionType.swap,
    status: status,
    createdAt: earliest,
    fromAsset: isPegIn ? Asset.btc : Asset.lbtc,
    toAsset: isPegIn ? Asset.lbtc : Asset.btc,
    sentAmount: sentAmount,
    receivedAmount: receivedAmount,
    sendTxId: sendTxId,
    receiveTxId: receiveTxId,
    sendBlockchain: isPegIn ? Blockchain.bitcoin : Blockchain.liquid,
    receiveBlockchain: isPegIn ? Blockchain.liquid : Blockchain.bitcoin,
  );
}

/// Content fingerprint over the fields the adapter + unifier read.
/// Cheap (one pass, no allocations) and stable: two upstream emissions
/// that produce the same UI list collapse to the same int.
int _fingerprint(List<v2.Transaction> txs) {
  // FNV-1a-style accumulator over the dimensions the downstream
  // pipeline actually consumes. Anything else changing upstream is
  // invisible to the home list and can safely be ignored.
  //
  // IMPORTANT: any field `_mergeBreezPegSwaps` or `_v2ToLegacy` reads
  // MUST be folded in here, otherwise a sync that flips it (e.g. the
  // Breez chain-swap re-sync that populates `swapLockupTxId` for the
  // first time) hits the cache and the home keeps showing the
  // pre-merge two-row view. This caused the peg-out to stay
  // unmerged after the Breez rebuild — the row's content was
  // semantically unchanged by the legacy fingerprint, so we kept
  // serving the cached "Enviou BTC L2" + "Recebeu BTC" pair.
  var h = 0x811C9DC5;
  for (final t in txs) {
    h = _mix(h, t.id.hashCode);
    h = _mix(h, t.status.index);
    h = _mix(h, t.direction.index);
    h = _mix(h, t.amountSat);
    h = _mix(h, t.timestamp.millisecondsSinceEpoch);
    final sa = t.sentAmountSat;
    final ra = t.receivedAmountSat;
    if (sa != null) h = _mix(h, sa);
    if (ra != null) h = _mix(h, ra);
    final aid = t.assetId;
    if (aid != null) h = _mix(h, aid.hashCode);
    final src = t.source;
    if (src != null) h = _mix(h, src.index);
    final lockup = t.swapLockupTxId;
    if (lockup != null) h = _mix(h, lockup.hashCode);
    final claim = t.swapClaimTxId;
    if (claim != null) h = _mix(h, claim.hashCode);
  }
  // Mix the length too so an extra trailing item with all-default
  // values still flips the fingerprint.
  return _mix(h, txs.length);
}

int _mix(int h, int value) {
  // Truncate to 32 bits to keep the accumulator stable across web
  // (where ints are doubles) and native.
  return ((h ^ value) * 0x01000193) & 0xFFFFFFFF;
}

legacy.Transaction _v2ToLegacy(v2.Transaction t) {
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
