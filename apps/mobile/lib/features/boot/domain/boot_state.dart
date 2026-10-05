import '../../../domain/failures/failure.dart';

enum BootPhase {
  idle,
  initializingPlatform,
  initializingDatabase,
  loadingCredentials,
  connectingServices,
  authenticatingSession,
  ready,
  needsSetup,
  error,
}

class BootState {
  const BootState({
    required this.phase,
    this.failure,
    this.startedAt,
    this.completedAt,
    this.lastPhaseDurationMs,
  });

  final BootPhase phase;
  final BootFailure? failure;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? lastPhaseDurationMs;

  bool get isTerminal =>
      phase == BootPhase.ready ||
      phase == BootPhase.needsSetup ||
      phase == BootPhase.error;

  bool get isReady => phase == BootPhase.ready;

  BootState copyWith({
    BootPhase? phase,
    BootFailure? failure,
    DateTime? startedAt,
    DateTime? completedAt,
    int? lastPhaseDurationMs,
    bool clearFailure = false,
  }) {
    return BootState(
      phase: phase ?? this.phase,
      failure: clearFailure ? null : (failure ?? this.failure),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastPhaseDurationMs: lastPhaseDurationMs ?? this.lastPhaseDurationMs,
    );
  }

  static const BootState idle = BootState(phase: BootPhase.idle);
}
