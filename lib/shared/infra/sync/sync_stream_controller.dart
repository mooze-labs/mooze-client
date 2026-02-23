import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { idle, syncing, completed, error }

enum TransactionEventType {
  newTransaction,
  statusChanged,
  confirmationsChanged,
}

class TransactionEvent {
  final String txId;
  final TransactionEventType eventType;
  final String blockchain;
  final String? oldStatus;
  final String? newStatus;
  final int? oldConfirmations;
  final int? newConfirmations;
  final DateTime timestamp;

  const TransactionEvent({
    required this.txId,
    required this.eventType,
    required this.blockchain,
    this.oldStatus,
    this.newStatus,
    this.oldConfirmations,
    this.newConfirmations,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'TransactionEvent(txId: $txId, type: $eventType, blockchain: $blockchain)';
  }
}

class SyncProgress {
  final String datasource;
  final SyncStatus status;
  final int? totalItems;
  final int? processedItems;
  final String? errorMessage;
  final DateTime timestamp;
  final List<TransactionEvent>? transactionEvents;

  const SyncProgress({
    required this.datasource,
    required this.status,
    this.totalItems,
    this.processedItems,
    this.errorMessage,
    required this.timestamp,
    this.transactionEvents,
  });

  double? get progress {
    if (totalItems == null || processedItems == null) return null;
    if (totalItems == 0) return 1.0;
    return processedItems! / totalItems!;
  }

  @override
  String toString() {
    return 'SyncProgress(datasource: $datasource, status: $status, progress: ${progress?.toStringAsFixed(2) ?? "N/A"})';
  }
}

class SyncStreamController {
  final _controller = StreamController<SyncProgress>.broadcast();
  final _transactionController = StreamController<TransactionEvent>.broadcast();

  SyncStreamController();

  Stream<SyncProgress> get stream => _controller.stream;

  Stream<TransactionEvent> get transactionStream =>
      _transactionController.stream;

  int get transactionListenerCount {
    return _transactionController.hasListener ? 1 : 0;
  }

  void updateProgress(SyncProgress progress) {
    if (!_controller.isClosed) {
      _controller.add(progress);

      if (progress.transactionEvents != null &&
          progress.transactionEvents!.isNotEmpty) {
        for (final event in progress.transactionEvents!) {
          emitTransactionEvent(event);
        }
      }
    }
  }

  void emitTransactionEvent(TransactionEvent event) {
    if (!_transactionController.isClosed) {
      _transactionController.add(event);
    }
  }

  void dispose() {
    _controller.close();
    _transactionController.close();
  }
}

final syncStreamProvider = Provider<SyncStreamController>((ref) {
  final controller = SyncStreamController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final datasourceSyncProgressProvider =
    StreamProvider.family<SyncProgress, String>((ref, datasource) {
      final syncStream = ref.watch(syncStreamProvider);
      return syncStream.stream.where((p) => p.datasource == datasource);
    });

final anySyncInProgressProvider = StreamProvider<bool>((ref) {
  final syncStream = ref.watch(syncStreamProvider);

  bool lastState = false;

  return syncStream.stream.map((p) {
    if (p.status == SyncStatus.syncing) {
      lastState = true;
    } else if (p.status == SyncStatus.completed ||
        p.status == SyncStatus.error) {
      lastState = false;
    }
    return lastState;
  });
});

final allSyncStatusProvider = StreamProvider<Map<String, SyncStatus>>((ref) {
  final syncStream = ref.watch(syncStreamProvider);
  final statusMap = <String, SyncStatus>{};

  return syncStream.stream.map((p) {
    statusMap[p.datasource] = p.status;
    return Map.from(statusMap);
  });
});
