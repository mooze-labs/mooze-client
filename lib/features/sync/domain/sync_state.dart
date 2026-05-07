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
  });

  final SyncPhase phase;
  final Map<ChainId, ServiceLifecycle> perChain;
  final SyncFailure? lastError;
  final DateTime? lastSuccessAt;
  final Duration? lastDuration;

  SyncState copyWith({
    SyncPhase? phase,
    Map<ChainId, ServiceLifecycle>? perChain,
    SyncFailure? lastError,
    DateTime? lastSuccessAt,
    Duration? lastDuration,
    bool clearError = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      perChain: perChain ?? this.perChain,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastDuration: lastDuration ?? this.lastDuration,
    );
  }

  static SyncState idle() => const SyncState(phase: SyncPhase.idle, perChain: {});
}
