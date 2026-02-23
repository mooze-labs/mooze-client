import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/transaction_monitor_service.dart';

final transactionMonitorServiceProvider = Provider<TransactionMonitorService>((
  ref,
) {
  final service = TransactionMonitorService(ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final transactionStatusStreamProvider = StreamProvider((ref) {
  final service = ref.watch(transactionMonitorServiceProvider);
  return service.statusUpdates;
});
