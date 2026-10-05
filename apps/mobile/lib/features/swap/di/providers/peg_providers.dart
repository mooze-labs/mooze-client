import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/di/providers/swap_audit_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';

import '../../data/repositories/core_peg_orchestrator.dart';
import '../../data/repositories/core_peg_tracker.dart';
import '../../domain/entities/peg.dart';
import '../../domain/usecases/peg_orchestrator.dart';
import '../../domain/usecases/peg_tracker.dart';
import 'swap_repository_provider.dart';

/// Drives a peg from quote through funding, scoped to the active wallet.
final pegOrchestratorProvider = Provider<PegOrchestrator>((ref) {
  return CorePegOrchestrator(
    session: ref.watch(coreSideswapSessionProvider),
    walletId: ref.watch(walletIdProvider.future),
    audit: ref.read(swapAuditRepositoryProvider),
  );
});

final pegLimitsProvider = FutureProvider<PegServerLimits?>((ref) async {
  final result = await ref.watch(pegOrchestratorProvider).limits().run();
  return result.toNullable();
});

/// Long-lived status poller. A plain [Provider], so it survives the swap
/// screen being disposed.
final pegTrackerProvider = FutureProvider<PegTracker>((ref) async {
  final tracker = CorePegTracker(
    session: ref.watch(coreSideswapSessionProvider),
    walletId: ref.watch(walletIdProvider.future),
  );
  ref.onDispose(tracker.dispose);
  unawaited(tracker.restore().catchError((Object _) {}));
  return tracker;
});

/// Live view of in-flight pegs for the UI.
final activePegsProvider = StreamProvider<List<TrackedPeg>>((ref) async* {
  final tracker = await ref.watch(pegTrackerProvider.future);
  yield tracker.current;
  yield* tracker.pegs;
});
