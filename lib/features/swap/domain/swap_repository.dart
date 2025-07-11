import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/swap/domain/entities/swap_operation.dart';

abstract class SwapRepository {
  Future<double> getSwapRate(Asset sendAsset, Asset receiveAsset);
  Future<SwapOperation> startNewSwapOperation(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
  );
}
