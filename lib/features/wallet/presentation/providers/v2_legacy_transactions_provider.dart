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
          final tUnify = DateTime.now();
          result = unifyPegSwaps(adapted);
          final unifyMs = DateTime.now().difference(tUnify).inMilliseconds;
          BootTracer.mark('v2_legacy_txs.inline.after', {
            'n': seq,
            'adapt_ms': adaptMs,
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
  // Collapse Breez peg-in / peg-out clusters (anchor + BDK leg +
  // LWK/Breez leg + duplicate cross-chain views) into a single
  // swap row before reaching the home transaction list. See
  // `swap_unifier.dart` for the matching rules.
  return unifyPegSwaps(input.map(_v2ToLegacy).toList(growable: false));
}

/// Content fingerprint over the fields the adapter + unifier read.
/// Cheap (one pass, no allocations) and stable: two upstream emissions
/// that produce the same UI list collapse to the same int.
int _fingerprint(List<v2.Transaction> txs) {
  // FNV-1a-style accumulator over the dimensions the downstream
  // pipeline actually consumes. Anything else changing upstream is
  // invisible to the home list and can safely be ignored.
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
