import '../../domain/failures/failure.dart';

enum AppPhase {
  uninitialized,
  booting,
  ready,
  needsSetup,
  shuttingDown,
  terminated,
  error,
}

class AppState {
  const AppState({
    required this.phase,
    this.failure,
    this.startedAt,
    this.readyAt,
  });

  final AppPhase phase;
  final Failure? failure;
  final DateTime? startedAt;
  final DateTime? readyAt;

  AppState copyWith({
    AppPhase? phase,
    Failure? failure,
    DateTime? startedAt,
    DateTime? readyAt,
    bool clearFailure = false,
  }) {
    return AppState(
      phase: phase ?? this.phase,
      failure: clearFailure ? null : (failure ?? this.failure),
      startedAt: startedAt ?? this.startedAt,
      readyAt: readyAt ?? this.readyAt,
    );
  }

  static const AppState uninitialized = AppState(phase: AppPhase.uninitialized);
}
