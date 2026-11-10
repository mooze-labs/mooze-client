import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';

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

    final feeRateSatPerVByte = await ref.watch(
      bitcoinSendFeeRateProvider.future,
    );

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
