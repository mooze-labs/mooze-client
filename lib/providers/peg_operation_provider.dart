import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/services/peg_persistence.dart';

part 'peg_operation_provider.g.dart';

final pegPersistenceServiceProvider = Provider<PegPersistenceService>((ref) {
  return PegPersistenceService();
});

@Riverpod(keepAlive: true)
class ActivePegOperation extends _$ActivePegOperation {
  @override
  Future<PegOperation?> build() async {
    final service = ref.read(pegPersistenceServiceProvider);
    final operation = await service.getActivePegOperation();

    // Return null if no operation exists or if it's expired
    if (operation == null || !service.isOperationValid(operation)) {
      await service.clearActivePegOperation();
      return null;
    }

    return operation;
  }

  Future<void> startPegOperation(String orderId, bool isPegIn) async {
    final service = ref.read(pegPersistenceServiceProvider);
    final operation = PegOperation(
      orderId: orderId,
      isPegIn: isPegIn,
      createdAt: DateTime.now(),
    );

    await service.saveActivePegOperation(operation);
    state = AsyncValue.data(operation);
  }

  Future<void> completePegOperation() async {
    final service = ref.read(pegPersistenceServiceProvider);
    await service.clearActivePegOperation();
    state = const AsyncValue.data(null);
  }
}
