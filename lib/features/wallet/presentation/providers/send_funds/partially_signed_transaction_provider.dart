import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'clean_address_provider.dart';
import 'amount_provider.dart';
import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';
import 'drain_provider.dart';
import 'fee_speed_provider.dart';

final psbtProvider = FutureProvider<Either<String, PartiallySignedTransaction>>(
  (ref) async {
    final walletController = await ref.read(walletControllerProvider.future);
    final destination = ref.watch(cleanAddressProvider);
    final asset = ref.watch(selectedAssetProvider);
    final blockchain = ref.watch(selectedNetworkProvider);
    final finalAmount = ref.watch(finalAmountProvider);
    final amount = BigInt.from(finalAmount);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);

    int? feeRateSatPerVByte;
    if (asset == Asset.btc && blockchain == Blockchain.bitcoin) {
      final selectedFeeSpeed = ref.watch(feeSpeedProvider);
      final feeService = BitcoinFeeService();
      final feeEstimate = await feeService.fetchFeeEstimate();

      if (feeEstimate != null) {
        switch (selectedFeeSpeed) {
          case FeeSpeed.low:
            feeRateSatPerVByte = feeEstimate.lowFeeSatPerVByte;
            break;
          case FeeSpeed.medium:
            feeRateSatPerVByte = feeEstimate.mediumFeeSatPerVByte;
            break;
          case FeeSpeed.fast:
            feeRateSatPerVByte = feeEstimate.fastFeeSatPerVByte;
            break;
        }
      }
    }

    return walletController.match(
      (error) {
        return Either<String, PartiallySignedTransaction>.left(
          error.toString(),
        );
      },
      (controller) {
        if (isDrainTransaction) {
          return controller
              .beginDrainTransaction(
                destination: destination,
                asset: asset,
                blockchain: blockchain,
                amount: amount,
                feeRateSatPerVByte: feeRateSatPerVByte,
              )
              .run();
        } else {
          return controller
              .beginNewTransaction(
                destination: destination,
                asset: asset,
                blockchain: blockchain,
                amount: amount,
                feeRateSatPerVByte: feeRateSatPerVByte,
              )
              .run();
        }
      },
    );
  },
);
