import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/usecases/refresh_wallet.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';

/// Stagger times for the post-swap refresh sequence. The first tick
/// catches the swap row the chain backends have *already* observed
/// (typical case for Breez SDK, which surfaces the new payment
/// synchronously). The second tick catches BDK/LWK reconciliations
/// that need a fresh Esplora poll. The third tick catches the on-
/// chain confirmation when it lands a block or two later for fast
/// fees.
///
/// All ticks share the single-flight mutex inside `SyncOrchestrator`,
/// so an in-flight refresh swallows the next request rather than
/// piling up.
const _refreshSchedule = <Duration>[
  Duration.zero,
  Duration(seconds: 3),
  Duration(seconds: 15),
];

/// Apply known asset deltas to the cached service balances so the
/// home screen reflects the swap immediately, then invalidate the
/// balance providers so the UI re-pulls the freshly-mutated cache.
///
/// Why this is separate from [triggerPostSwapRefresh]: SideSwap
/// broadcasts the tx via its own server, NOT via Breez SDK. Neither
/// `c.getInfo()` (Breez) nor `w.balances()` (LWK) reflect the new
/// state until the corresponding electrum endpoint indexes the
/// mempool tx — which can take 5–30 s in practice. Until then,
/// every `sync()` returns `changed=0` and the UI shows the
/// pre-swap balance.
///
/// The fix: directly mutate the cached `_lastBalance` on both
/// services with the known swap deltas (-send, +receive). The
/// next successful sync overwrites the cache with the real values,
/// so the optimistic update is *transparently* corrected if the
/// swap details we computed turn out to be off (e.g. server fee
/// differs from what the UI showed).
///
/// Best-effort: any failure here is logged and swallowed — the
/// caller's `triggerPostSwapRefresh` still runs as the fallback.
void triggerPostSwapOptimisticBalanceUpdate(
  WidgetRef ref, {
  required String sendAssetId,
  required int sendAmountSat,
  required String receiveAssetId,
  required int receiveAmountSat,
}) {
  if (sendAmountSat <= 0 && receiveAmountSat <= 0) return;
  // Apply the same deltas to both services. Breez is the primary
  // resolver for all Liquid assets at the home screen (see
  // `Asset.<x>.resolutionChains == [lightning, liquid]`), so its
  // cache is the one users actually see; LWK is updated for parity
  // and so screens that read LWK directly (e.g. utxo / debug views)
  // also see consistent state.
  // Accumulate per-asset deltas so a (nonsensical but defensible)
  // same-asset swap doesn't clobber itself on the second key write.
  final deltas = <String, int>{};
  deltas.update(
    sendAssetId,
    (prev) => prev - sendAmountSat,
    ifAbsent: () => -sendAmountSat,
  );
  deltas.update(
    receiveAssetId,
    (prev) => prev + receiveAmountSat,
    ifAbsent: () => receiveAmountSat,
  );

  Future<void>.microtask(() async {
    try {
      final lightning = ref.read(lightningWalletServiceProvider);
      final liquid = ref.read(liquidWalletServiceProvider);
      await Future.wait([
        lightning.applyOptimisticBalanceDelta(deltas: deltas),
        liquid.applyOptimisticBalanceDelta(deltas: deltas),
      ]);
      // Nudge the home screen to re-read the freshly-mutated cache.
      // `allBalancesProvider` is the unified read used by the home
      // balance widget; invalidating it re-runs the fan-out and
      // surfaces our optimistic numbers in the same frame.
      ref.invalidate(allBalancesProvider);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[post-swap-balance] optimistic update failed: $e — falling back to '
          'next sync',
        );
      }
    }
  });
}

/// Fire-and-forget staggered wallet refresh used by every swap
/// completion path (peg-in, peg-out, single-tx Liquid asset swap,
/// confirm-bottom-sheet flow). Resolves the use case once up front
/// while the widget's `ref` is still alive, then drives subsequent
/// refreshes off the captured use-case reference so a widget unmount
/// mid-sequence doesn't break anything.
///
/// Strategy is always [SyncStrategy.light] — the orchestrator
/// already does the heavy chain rescan on its own ticker; we just
/// want to nudge it to run *now* and again shortly after.
void triggerPostSwapRefresh(WidgetRef ref) {
  Future<void>.microtask(() async {
    final RefreshWalletUseCase useCase;
    try {
      useCase = await ref.read(refreshWalletProvider.future);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[post-swap-refresh] could not resolve use case: $e');
      }
      return;
    }

    for (final delay in _refreshSchedule) {
      if (delay > Duration.zero) await Future.delayed(delay);
      try {
        await useCase(strategy: SyncStrategy.light);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[post-swap-refresh] tick +${delay.inSeconds}s failed: $e',
          );
        }
        // Continue to the next tick anyway — a transient failure on
        // one refresh shouldn't cancel the whole sequence.
      }
    }
  });
}
