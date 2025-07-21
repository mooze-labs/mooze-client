import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/swap/domain/entities/swap_operation.dart';

abstract class SwapRepository {
  TaskEither<String, double> getSwapRate(Asset sendAsset, Asset receiveAsset);
  TaskEither<String, SwapOperation> startNewSwapOperation(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
  );
  TaskEither<String, String> confirmSwap(SwapOperation operation);
}
