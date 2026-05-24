import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/refund.dart' as v2refund;
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Phases an optimistic peg swap moves through between "user confirmed
/// the swap" and "the persisted transaction store has caught up".
///
/// The pipeline is intentionally short: once the persisted store
/// surfaces a matching row (`pendingSwapsReconciliationProvider` does
/// the match), the optimistic record is dropped and the home list
/// renders the real one instead.
enum PendingSwapPhase {
  /// User confirmed, the SDK call is being prepared (address fetch,
  /// fee estimate, audit row recorded).
  preparing,

  /// SDK call is in-flight — the LBTC PSET is being signed and handed
  /// to the Boltz lockup / Breez chain-swap broadcaster.
  broadcasting,

  /// SDK returned a Payment. The lockup tx is on the wire; we are
  /// waiting for the persisted store to surface the Breez swap row
  /// (then `reconcile` retires the optimistic entry).
  broadcasted,

  /// SDK or repository returned an error. Rendered briefly as a red
  /// row, then auto-evicted after [_failedRetentionDuration].
  failed,

  /// Boltz / Breez has flagged the swap as refundable — typically
  /// because the lockup tx never reached the expected amount, the
  /// swap timed out, or the claim path is otherwise blocked. The
  /// optimistic row stops looking like "in progress" and switches to
  /// a refund-focused affordance ("Tap to claim refund") that hands
  /// off to the existing `GetRefundScreen` flow. Stays in this phase
  /// until either the refund BTC lands back in the wallet (reconciler
  /// retires it) or [_maxAge] expires.
  refundable,
}

class PendingSwap {
  final String localId;
  final Asset fromAsset;
  final Asset toAsset;
  final BigInt sentAmount;
  final BigInt estimatedReceivedAmount;
  final String? destination;
  final PendingSwapPhase phase;
  final DateTime createdAt;
  final String? breezSwapId;
  final String? breezTxId;
  final String? errorMessage;
  // Boltz swap address (source-chain lockup destination). Captured
  // when available so the refund watcher can match this row against
  // `RefundableSwap.swapAddress` exactly, instead of relying on the
  // weaker amount + time heuristic.
  final String? swapAddress;

  const PendingSwap({
    required this.localId,
    required this.fromAsset,
    required this.toAsset,
    required this.sentAmount,
    required this.estimatedReceivedAmount,
    required this.destination,
    required this.phase,
    required this.createdAt,
    this.breezSwapId,
    this.breezTxId,
    this.errorMessage,
    this.swapAddress,
  });

  bool get isPegOut => fromAsset == Asset.lbtc && toAsset == Asset.btc;
  bool get isPegIn => fromAsset == Asset.btc && toAsset == Asset.lbtc;

  PendingSwap copyWith({
    PendingSwapPhase? phase,
    String? breezSwapId,
    String? breezTxId,
    String? errorMessage,
    String? swapAddress,
  }) {
    return PendingSwap(
      localId: localId,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount,
      estimatedReceivedAmount: estimatedReceivedAmount,
      destination: destination,
      createdAt: createdAt,
      phase: phase ?? this.phase,
      breezSwapId: breezSwapId ?? this.breezSwapId,
      breezTxId: breezTxId ?? this.breezTxId,
      errorMessage: errorMessage ?? this.errorMessage,
      swapAddress: swapAddress ?? this.swapAddress,
    );
  }

  /// Serialise to JSON for SharedPreferences persistence.
  /// `Asset` round-trips via its [Asset.id] (the stable hex asset id),
  /// not its enum `.name` — that getter is overridden on `Asset` to
  /// return a human-facing label like "Bitcoin", which `Asset.values
  /// .byName()` can't resolve. Phase uses the enum identifier name
  /// (no override there). `BigInt`s as decimal strings; timestamp as
  /// ms-since-epoch.
  Map<String, dynamic> toJson() => {
        'localId': localId,
        'fromAsset': fromAsset.id,
        'toAsset': toAsset.id,
        'sentAmount': sentAmount.toString(),
        'estimatedReceivedAmount': estimatedReceivedAmount.toString(),
        'destination': destination,
        'phase': phase.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'breezSwapId': breezSwapId,
        'breezTxId': breezTxId,
        'errorMessage': errorMessage,
        'swapAddress': swapAddress,
      };

  static PendingSwap fromJson(Map<String, dynamic> json) {
    return PendingSwap(
      localId: json['localId'] as String,
      fromAsset: Asset.fromId(json['fromAsset'] as String),
      toAsset: Asset.fromId(json['toAsset'] as String),
      sentAmount: BigInt.parse(json['sentAmount'] as String),
      estimatedReceivedAmount:
          BigInt.parse(json['estimatedReceivedAmount'] as String),
      destination: json['destination'] as String?,
      phase: PendingSwapPhase.values.byName(json['phase'] as String),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      breezSwapId: json['breezSwapId'] as String?,
      breezTxId: json['breezTxId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      swapAddress: json['swapAddress'] as String?,
    );
  }
}

/// Optimistic-swap store. Persists to SharedPreferences so hot
/// restarts and full app kills don't strand the user with "where did
/// my money go" mid-swap — on cold start the saved rows hydrate
/// before the home list mounts and the reconciler picks up where it
/// left off as soon as the V2 store finishes its first emission.
///
/// Storage layout: a single JSON-encoded array under [_storageKey].
/// Schema is name-keyed (enums) and string-keyed (BigInt as decimal
/// string) so we can evolve the value types without silently
/// remapping older rows. If parsing fails (corrupt blob, mid-schema
/// version skew), the blob is dropped and state starts empty —
/// degraded path, not a crash.
class PendingSwapsNotifier extends Notifier<List<PendingSwap>> {
  static const _storageKey = 'pending_swaps_v1';
  static const _failedRetentionDuration = Duration(seconds: 8);
  // Defensive cap: a swap that never gets reconciled (SDK crashed
  // mid-flight, the persisted store never surfaced the destination
  // credit) shouldn't sit in storage forever. Filtered out both on
  // load (so a stale row from days ago doesn't haunt the home list)
  // and on every `reconcileWith` pass.
  static const _maxAge = Duration(hours: 6);
  // Refund detection is a poll (Breez doesn't push refundable state
  // into the V2 transaction store — the only authoritative API is
  // `listRefundableSwaps`). 30 s is fast enough to feel responsive
  // and cheap enough to leave on permanently; the call is skipped
  // entirely when nothing is in `broadcasted` phase.
  static const _refundPollInterval = Duration(seconds: 30);

  // Monotonic counter on top of the timestamp so two starts within
  // the same millisecond get unique ids.
  int _seq = 0;

  late final SharedPreferences _prefs;
  Timer? _refundTimer;

  @override
  List<PendingSwap> build() {
    _prefs = ref.read(sharedPreferencesProvider);
    _startRefundWatcher();
    return _loadFromPrefs();
  }

  void _startRefundWatcher() {
    _refundTimer?.cancel();
    _refundTimer = Timer.periodic(
      _refundPollInterval,
      (_) => _pollRefundableSwaps(),
    );
    ref.onDispose(() => _refundTimer?.cancel());
  }

  Future<void> _pollRefundableSwaps() async {
    // Two things happen in this tick when there's an in-flight swap:
    //
    //   1. Refund detection — only for peg-ins. Peg-out refunds are
    //      auto-handled by Breez (the LBTC returns to LWK without
    //      user action); surfacing a "Tap to claim refund" CTA there
    //      would mislead the user. Peg-out failures retire through
    //      `_isRefundLanded` when the LBTC shows up on the source
    //      chain.
    //
    //   2. Swap-id enrichment — for any broadcasted row whose
    //      `breezSwapId` is still missing (or stale-equals the
    //      lockup tx id, which is what the helper used to write).
    //      Looks up the real short Breez id via `findBreezChainSwapId`
    //      and stores it. Cheap: the SDK call is the same regardless
    //      of direction, so we run it for peg-in *and* peg-out.
    final refundCandidates = state
        .where((p) =>
            p.phase == PendingSwapPhase.broadcasted && p.isPegIn)
        .toList(growable: false);
    final enrichCandidates = state
        .where((p) =>
            p.phase == PendingSwapPhase.broadcasted &&
            p.breezTxId != null &&
            (p.breezSwapId == null || p.breezSwapId == p.breezTxId))
        .toList(growable: false);
    if (refundCandidates.isEmpty && enrichCandidates.isEmpty) return;
    await _enrichBreezSwapIds(enrichCandidates);
    if (refundCandidates.isEmpty) return;
    final candidates = refundCandidates;

    final repoAsync = ref.read(walletRepositoryProvider);
    final repo = repoAsync.valueOrNull;
    if (repo == null) return;

    // V2 repo returns a Future<Either<...>> directly (the legacy
    // TaskEither wrapper lives in the other repo impl).
    final result = await repo.listRefundableSwaps();
    result.match(
      (failure) {
        if (kDebugMode) {
          debugPrint('[BREEZ-REFUND] poll failed: $failure');
        }
      },
      (refundables) {
        if (kDebugMode) {
          debugPrint(
            '[BREEZ-REFUND] poll returned ${refundables.length} refundable '
            'swap(s); checking against ${candidates.length} candidate(s)',
          );
          for (final r in refundables) {
            debugPrint(
              '[BREEZ-REFUND]   swap addr=${r.swapAddress} '
              'amountSat=${r.amountSat} lastRefundTx=${r.lastRefundTxId} '
              'ts=${r.timestamp}',
            );
          }
        }
        for (final r in refundables) {
          for (final p in candidates) {
            if (_matchesRefundable(p, r)) {
              if (kDebugMode) {
                debugPrint(
                  '[BREEZ-REFUND] match → flipping ${p.localId} to '
                  'refundable (addr=${r.swapAddress})',
                );
              }
              markRefundable(
                p.localId,
                swapAddress: r.swapAddress,
              );
              break;
            }
          }
        }
      },
    );
  }

  bool _matchesRefundable(PendingSwap pending, v2refund.RefundableSwap r) {
    // Strongest match: the swap address we captured at broadcast time
    // equals the refundable's lockup address. Falls back to amount +
    // timestamp when no address was captured (e.g. swaps started
    // before address capture was wired in, restored from prefs).
    if (pending.swapAddress != null && pending.swapAddress == r.swapAddress) {
      return true;
    }
    if (r.timestamp != null && r.timestamp!.isBefore(pending.createdAt)) {
      return false; // belongs to an older swap
    }
    return _amountsApproxMatch(
      BigInt.from(r.amountSat),
      pending.sentAmount,
      0.05,
    );
  }

  void markRefundable(String localId, {String? swapAddress}) {
    state = [
      for (final s in state)
        if (s.localId == localId)
          s.copyWith(
            phase: PendingSwapPhase.refundable,
            swapAddress: swapAddress,
          )
        else
          s,
    ];
    _persist();
  }

  /// Stores the real Breez short swap id (`wCaunaTNZaHv`-style) once
  /// the poll has enriched it from `findBreezChainSwapId`. Idempotent
  /// — if the stored id already matches, no state churn or persist
  /// happens (avoids waking the home list for no reason).
  void setBreezSwapId(String localId, String swapId) {
    var changed = false;
    state = [
      for (final s in state)
        if (s.localId == localId && s.breezSwapId != swapId)
          () {
            changed = true;
            return s.copyWith(breezSwapId: swapId);
          }()
        else
          s,
    ];
    if (changed) _persist();
  }

  /// For each pending in [candidates], hit Breez to resolve the real
  /// chain-swap id and persist it. Failures are silently retried on
  /// the next poll tick. Called from [_pollRefundableSwaps] alongside
  /// the refund detection so we only spawn one timer.
  Future<void> _enrichBreezSwapIds(List<PendingSwap> candidates) async {
    if (candidates.isEmpty) return;
    final repoAsync = ref.read(walletRepositoryProvider);
    final repo = repoAsync.valueOrNull;
    if (repo == null) return;

    for (final p in candidates) {
      final lockupTxId = p.breezTxId;
      if (lockupTxId == null) continue;
      final result =
          await repo.findBreezChainSwapId(lockupTxId: lockupTxId);
      result.match(
        (failure) {
          if (kDebugMode) {
            debugPrint(
              '[BREEZ-SWAP-ID] enrichment failed for ${p.localId}: $failure',
            );
          }
        },
        (swapId) {
          if (swapId == null) {
            if (kDebugMode) {
              debugPrint(
                '[BREEZ-SWAP-ID] no swap yet for lockup=$lockupTxId '
                '(${p.localId}) — will retry next poll',
              );
            }
            return;
          }
          if (kDebugMode) {
            debugPrint(
              '[BREEZ-SWAP-ID] enriched ${p.localId}: $swapId '
              '(lockup=$lockupTxId)',
            );
          }
          setBreezSwapId(p.localId, swapId);
        },
      );
    }
  }

  List<PendingSwap> _loadFromPrefs() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(PendingSwap.fromJson)
          .toList(growable: false);
      final now = DateTime.now();
      return list
          .where((s) => now.difference(s.createdAt) <= _maxAge)
          .toList(growable: false);
    } catch (e, st) {
      // Schema change, partial write, or someone tampered with the
      // value — log + drop, never crash on a cold start.
      debugPrint('[PendingSwapsNotifier] load failed, dropping blob: $e\n$st');
      _prefs.remove(_storageKey);
      return const [];
    }
  }

  void _persist() {
    if (state.isEmpty) {
      // Avoid leaving an empty "[]" string under the key — clean
      // wipe keeps hot-restart's first read trivial.
      _prefs.remove(_storageKey);
      return;
    }
    final json =
        jsonEncode(state.map((s) => s.toJson()).toList(growable: false));
    _prefs.setString(_storageKey, json);
  }

  String start({
    required Asset fromAsset,
    required Asset toAsset,
    required BigInt sentAmount,
    required BigInt estimatedReceivedAmount,
    String? destination,
  }) {
    final localId = 'pending_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';
    final swap = PendingSwap(
      localId: localId,
      fromAsset: fromAsset,
      toAsset: toAsset,
      sentAmount: sentAmount,
      estimatedReceivedAmount: estimatedReceivedAmount,
      destination: destination,
      phase: PendingSwapPhase.preparing,
      createdAt: DateTime.now(),
    );
    state = [...state, swap];
    _persist();
    return localId;
  }

  void markBroadcasting(String localId) {
    _updatePhase(localId, PendingSwapPhase.broadcasting);
  }

  void markBroadcasted(
    String localId, {
    String? breezSwapId,
    String? breezTxId,
  }) {
    state = [
      for (final s in state)
        if (s.localId == localId)
          s.copyWith(
            phase: PendingSwapPhase.broadcasted,
            breezSwapId: breezSwapId,
            breezTxId: breezTxId,
          )
        else
          s,
    ];
    _persist();
  }

  void markFailed(String localId, {String? error}) {
    state = [
      for (final s in state)
        if (s.localId == localId)
          s.copyWith(
            phase: PendingSwapPhase.failed,
            errorMessage: error,
          )
        else
          s,
    ];
    _persist();
    // Auto-evict failed rows after a short window so they show up,
    // communicate the failure, and then make space for the user to
    // retry without manual cleanup.
    Future.delayed(_failedRetentionDuration, () => clear(localId));
  }

  void clear(String localId) {
    state = [for (final s in state) if (s.localId != localId) s];
    _persist();
  }

  /// Called by [pendingSwapsReconciliationProvider] every time the
  /// persisted transaction list updates. Drops any optimistic row
  /// that the real store has caught up to, and any row that has
  /// outlived [_maxAge].
  void reconcileWith(List<Transaction> persisted) {
    if (state.isEmpty) return;

    final now = DateTime.now();
    final survivors = <PendingSwap>[];
    for (final pending in state) {
      if (now.difference(pending.createdAt) > _maxAge) {
        continue;
      }
      if (pending.phase == PendingSwapPhase.failed) {
        // Let the time-based eviction in `markFailed` handle these.
        survivors.add(pending);
        continue;
      }
      if (pending.phase == PendingSwapPhase.refundable) {
        // Refundable rows retire when the refund BTC lands back in
        // the wallet (a source-chain credit), not when the swap's
        // destination credit shows up — that one's never coming.
        if (_isRefundLanded(pending, persisted)) continue;
        survivors.add(pending);
        continue;
      }
      if (_isReconciled(pending, persisted)) {
        continue;
      }
      survivors.add(pending);
    }

    if (survivors.length != state.length) {
      state = survivors;
      _persist();
    }
  }

  void _updatePhase(String localId, PendingSwapPhase phase) {
    state = [
      for (final s in state)
        if (s.localId == localId) s.copyWith(phase: phase) else s,
    ];
    _persist();
  }
}

/// Refund landed on the source chain — peg-in's BTC refunded back
/// into the BDK wallet, or peg-out's LBTC refunded back into LWK.
/// Lighter than [_isReconciled]: no direction match against unified
/// swap rows (the refund tx is a plain receive, never paired by the
/// unifier into a swap row), and the amount tolerance is wider
/// because Boltz deducts its refund fee on top of the swap fee.
bool _isRefundLanded(PendingSwap pending, List<Transaction> persisted) {
  // Refund returns to the *source* chain (where the lockup came
  // from), not the destination — that's the whole point of a refund.
  final sourceBlockchain =
      pending.isPegIn ? Blockchain.bitcoin : Blockchain.liquid;
  final sourceAsset = pending.fromAsset;
  const window = Duration(hours: 12);
  const grace = Duration(seconds: 5);

  for (final t in persisted) {
    if (t.type != TransactionType.receive) continue;
    if (t.blockchain != sourceBlockchain || t.asset != sourceAsset) continue;
    final delta = t.createdAt.difference(pending.createdAt);
    if (delta < -grace) continue;
    if (delta > window) continue;
    // Wider tolerance — Boltz refund fee + miner fee can take a
    // noticeable chunk on small amounts (this is exactly the test
    // amount we're shipping, 3000 sats).
    if (_amountsApproxMatch(t.amount, pending.sentAmount, 0.30)) return true;
  }
  return false;
}

bool _isReconciled(PendingSwap pending, List<Transaction> persisted) {
  // The optimistic row should retire only when the *destination*
  // credit is actually visible — peg-in: an LBTC receive on Liquid;
  // peg-out: a BTC receive on Bitcoin. That's what tells the user
  // "your money actually arrived". Anything else — raw send legs,
  // partial unified swap rows that the unifier built before the
  // claim landed, historical LBTC receives from previous swaps —
  // leaves the optimistic row in place so the "in progress"
  // narrative survives.
  //
  // Critical: the matching persisted row must have been observed
  // *after* the optimistic was created. Otherwise an old LBTC
  // receive from a previous test swap with a similar amount falsely
  // retires the brand-new optimistic the instant the home list
  // renders (which is the bug the user just hit).
  final destBlockchain =
      pending.isPegIn ? Blockchain.liquid : Blockchain.bitcoin;
  final destAsset = pending.toAsset;
  const window = Duration(hours: 12);
  // Small grace for clock skew between device wall time and the
  // chain timestamps copied into the V2 store.
  const grace = Duration(seconds: 5);

  for (final t in persisted) {
    final delta = t.createdAt.difference(pending.createdAt);
    if (delta < -grace) continue; // historical — belongs to a previous swap
    if (delta > window) continue; // far future — clock skew or sync clamp

    // Case 1: unified swap row that already has the receive leg
    // paired by the unifier (peg-in/out both halves observed).
    if (_isUnifiedSwapMatchingDirection(t, pending) && t.receiveTxId != null) {
      if (_idsMatch(t, pending)) return true;
      final sent = t.sentAmount ?? t.amount;
      if (_amountsApproxMatch(sent, pending.sentAmount, 0.10)) return true;
    }

    // Case 2: a raw receive of the destination asset on its rail —
    // the user can now see the funds landed even if the unifier
    // hasn't paired the legs yet.
    if (t.type == TransactionType.receive &&
        t.asset == destAsset &&
        t.blockchain == destBlockchain) {
      if (_amountsApproxMatch(t.amount, pending.sentAmount, 0.10)) return true;
    }
  }
  return false;
}

bool _isUnifiedSwapMatchingDirection(Transaction t, PendingSwap pending) {
  if (t.type != TransactionType.swap) return false;
  if (pending.isPegIn) {
    return t.fromAsset == Asset.btc && t.toAsset == Asset.lbtc;
  }
  if (pending.isPegOut) {
    return t.fromAsset == Asset.lbtc && t.toAsset == Asset.btc;
  }
  return false;
}

bool _idsMatch(Transaction t, PendingSwap pending) {
  final swapId = pending.breezSwapId;
  if (swapId != null) {
    if (t.id == swapId) return true;
    if (t.sendTxId == swapId || t.receiveTxId == swapId) return true;
  }
  final txId = pending.breezTxId;
  if (txId != null) {
    if (t.id == txId) return true;
    if (t.sendTxId == txId || t.receiveTxId == txId) return true;
  }
  return false;
}

bool _amountsApproxMatch(BigInt a, BigInt b, double tolerance) {
  if (a == BigInt.zero || b == BigInt.zero) return false;
  final larger = a > b ? a : b;
  final smaller = a > b ? b : a;
  final diff = larger - smaller;
  return diff.toDouble() / larger.toDouble() <= tolerance;
}

final pendingSwapsProvider =
    NotifierProvider<PendingSwapsNotifier, List<PendingSwap>>(
  PendingSwapsNotifier.new,
);

/// Side-effect-only provider: watches the persisted transaction list
/// and trims the optimistic store as the real rows show up. Has no
/// readable value — consumers (the home transaction list)
/// `ref.watch` it just to keep the listener alive while they're on
/// screen.
final pendingSwapsReconciliationProvider = Provider<void>((ref) {
  ref.listen(
    v2LegacyTransactionsProvider,
    (_, next) {
      next.whenData((list) {
        ref.read(pendingSwapsProvider.notifier).reconcileWith(list);
      });
    },
    fireImmediately: true,
  );
});
