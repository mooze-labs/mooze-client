import '../../../domain/entities/chain.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/services/service_state.dart';

enum SyncPhase { idle, running, cooling, stopped }

class SyncState {
  const SyncState({
    required this.phase,
    required this.perChain,
    this.lastError,
    this.lastSuccessAt,
    this.lastDuration,
    this.firstSyncedChains = const <ChainId>{},
  });

  final SyncPhase phase;
  final Map<ChainId, ServiceLifecycle> perChain;
  final SyncFailure? lastError;
  final DateTime? lastSuccessAt;
  final Duration? lastDuration;

  /// Chains that have completed at least one sync cycle in the current
  /// session (success OR failure — both count as "we got an answer from
  /// the network for this chain"). Distinct from [perChain], which only
  /// reflects the SDK connection lifecycle (a chain can be `connected`
  /// at the SDK level for many seconds before its first sync returns).
  /// Drives per-chain "synced X" UX messaging and the import-loading
  /// gate that waits for specific chains' first sync.
  final Set<ChainId> firstSyncedChains;

  SyncState copyWith({
    SyncPhase? phase,
    Map<ChainId, ServiceLifecycle>? perChain,
    SyncFailure? lastError,
    DateTime? lastSuccessAt,
    Duration? lastDuration,
    Set<ChainId>? firstSyncedChains,
    bool clearError = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      perChain: perChain ?? this.perChain,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastDuration: lastDuration ?? this.lastDuration,
      firstSyncedChains: firstSyncedChains ?? this.firstSyncedChains,
    );
  }

  static SyncState idle() => const SyncState(phase: SyncPhase.idle, perChain: {});
}
