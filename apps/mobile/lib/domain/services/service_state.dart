import '../failures/failure.dart';

enum ServiceLifecycle {
  uninitialized,
  connecting,
  connected,
  disconnecting,
  disconnected,
  errored,
}

class ServiceState {
  const ServiceState({
    required this.lifecycle,
    this.failure,
    this.lastSyncAt,
  });

  final ServiceLifecycle lifecycle;
  final ServiceFailure? failure;
  final DateTime? lastSyncAt;

  bool get isOperational => lifecycle == ServiceLifecycle.connected;

  ServiceState copyWith({
    ServiceLifecycle? lifecycle,
    ServiceFailure? failure,
    DateTime? lastSyncAt,
    bool clearFailure = false,
  }) {
    return ServiceState(
      lifecycle: lifecycle ?? this.lifecycle,
      failure: clearFailure ? null : (failure ?? this.failure),
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  static const ServiceState initial =
      ServiceState(lifecycle: ServiceLifecycle.uninitialized);
}
