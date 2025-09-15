// Export providers
export 'swap_controller.dart';
export 'swap_operation_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/swap/domain/repositories.dart';
import 'package:mooze_mobile/features/swap/domain/entities.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/swap_operation_provider.dart'
    hide swapOperationNotifierProvider;
import 'package:mooze_mobile/features/swap/presentation/providers/swap_controller.dart';

class MockSwapRepository implements SwapRepository {
  @override
  TaskEither<String, double> getSwapRate(Asset sendAsset, Asset receiveAsset) {
    return TaskEither.fromTask(
      Task(() async {
        // Simulate network delay
        await Future.delayed(Duration(seconds: 1));

        // Mock exchange rates
        if (sendAsset == Asset.depix && receiveAsset == Asset.btc) {
          return 0.000009;
        } else if (sendAsset == Asset.btc && receiveAsset == Asset.depix) {
          return 111111.0;
        } else if (sendAsset == Asset.depix && receiveAsset == Asset.usdt) {
          return 1.0;
        } else if (sendAsset == Asset.usdt && receiveAsset == Asset.depix) {
          return 1.0;
        } else if (sendAsset == Asset.btc && receiveAsset == Asset.usdt) {
          return 98000.0;
        } else if (sendAsset == Asset.usdt && receiveAsset == Asset.btc) {
          return 0.00001;
        }
        return 1.0;
      }),
    );
  }

  @override
  TaskEither<String, SwapOperation> startNewSwapOperation(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
  ) {
    return TaskEither.fromTask(
      Task(() async {
        // Simulate network delay
        await Future.delayed(Duration(seconds: 2));

        // Mock swap operation - replace with actual implementation
        return SwapOperation(
          id: DateTime.now().millisecondsSinceEpoch,
          sendAsset: Asset.toId(sendAsset),
          receiveAsset: Asset.toId(receiveAsset),
          sendAmount: sendAmount,
          // receiveAmount will be calculated based on rates
          receiveAmount: BigInt.from(0),
          ttl: DateTime.now().add(Duration(minutes: 10)).millisecondsSinceEpoch,
        );
      }),
    );
  }

  @override
  TaskEither<String, String> confirmSwap(SwapOperation operation) {
    return TaskEither.fromTask(
      Task(() async {
        // Simulate network delay
        await Future.delayed(Duration(seconds: 3));

        // Mock confirmation - replace with actual implementation
        return 'mock_tx_${DateTime.now().millisecondsSinceEpoch}';
      }),
    );
  }
}

// Provide mock repository implementation
final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return MockSwapRepository();
});

// Override the operation provider with correct dependency
final swapOperationNotifierProvider =
    StateNotifierProvider<SwapOperationNotifier, SwapOperationState>((ref) {
      final repository = ref.watch(swapRepositoryProvider);
      return SwapOperationNotifier(repository);
    });

// Swap UI provider with correct dependency
final swapNotifierProvider = StateNotifierProvider<SwapNotifier, SwapUiState>((
  ref,
) {
  final repository = ref.watch(swapRepositoryProvider);
  return SwapNotifier(repository);
});
