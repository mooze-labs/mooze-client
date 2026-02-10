import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types of synchronization events
enum SyncEventType {
  started, // Sync started
  progress, // Sync progress (optional)
  completed, // Sync completed successfully
  failed, // Sync failed
}

/// Synchronization event
class SyncEvent {
  final String datasource; // 'liquid', 'bdk', 'breez'
  final SyncEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data; // Additional data (e.g. progress)
  final String? error;

  SyncEvent({
    required this.datasource,
    required this.type,
    required this.timestamp,
    this.data,
    this.error,
  });

  bool get isCompleted => type == SyncEventType.completed;
  bool get isFailed => type == SyncEventType.failed;
  bool get isStarted => type == SyncEventType.started;
  bool get isProgress => type == SyncEventType.progress;

  @override
  String toString() {
    return 'SyncEvent($datasource: $type at $timestamp${error != null ? ', error: $error' : ''})';
  }
}

/// Synchronization event controller
class SyncEventController {
  final _controller = StreamController<SyncEvent>.broadcast();
  final _completedDatasources = <String>{};
  final _startedDatasources = <String>{};

  Stream<SyncEvent> get stream => _controller.stream;
  Set<String> get completedDatasources =>
      Set.unmodifiable(_completedDatasources);
  Set<String> get startedDatasources => Set.unmodifiable(_startedDatasources);

  /// Emits a sync started event
  void emitStarted(String datasource) {
    _startedDatasources.add(datasource);
    _controller.add(
      SyncEvent(
        datasource: datasource,
        type: SyncEventType.started,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Emits a progress event (optional)
  void emitProgress(String datasource, Map<String, dynamic> progressData) {
    _controller.add(
      SyncEvent(
        datasource: datasource,
        type: SyncEventType.progress,
        timestamp: DateTime.now(),
        data: progressData,
      ),
    );
  }

  /// Emits a sync completed event
  void emitCompleted(String datasource) {
    print('[SyncEventController] emitCompleted called for: $datasource');
    // Prevents duplicate emission
    if (_completedDatasources.contains(datasource)) {
      print(
        '[SyncEventController] $datasource was already completed, ignoring',
      );
      return;
    }
    _completedDatasources.add(datasource);
    final event = SyncEvent(
      datasource: datasource,
      type: SyncEventType.completed,
      timestamp: DateTime.now(),
    );
    _controller.add(event);
  }

  /// Emits a failure event
  void emitFailed(String datasource, String error) {
    _controller.add(
      SyncEvent(
        datasource: datasource,
        type: SyncEventType.failed,
        timestamp: DateTime.now(),
        error: error,
      ),
    );
  }

  /// Checks if all datasources have completed
  bool allCompleted(List<String> datasources) {
    return datasources.every((ds) => _completedDatasources.contains(ds));
  }

  /// Checks if at least one datasource has completed
  bool anyCompleted() => _completedDatasources.isNotEmpty;

  /// Checks if a specific datasource has completed
  bool isCompleted(String datasource) =>
      _completedDatasources.contains(datasource);

  /// Resets the state
  void reset() {
    _completedDatasources.clear();
    _startedDatasources.clear();
  }

  void dispose() {
    _controller.close();
  }
}

/// Controller provider
final syncEventControllerProvider = Provider<SyncEventController>((ref) {
  final controller = SyncEventController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Event stream provider
final syncEventStreamProvider = StreamProvider<SyncEvent>((ref) {
  final controller = ref.watch(syncEventControllerProvider);
  return controller.stream;
});
