import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/usecases/refresh_wallet.dart';

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
