import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';

import 'address_provider.dart';
import 'amount_provider.dart';
import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';
import 'drain_provider.dart';

final psbtProvider = FutureProvider<Either<String, PartiallySignedTransaction>>(
  (ref) async {
    final walletController = await ref.read(walletControllerProvider.future);
    final destination = ref.watch(addressStateProvider);
    final asset = ref.watch(selectedAssetProvider);
    final blockchain = ref.watch(selectedNetworkProvider);
    final amount = BigInt.from(ref.watch(finalAmountProvider));

    final isDrainTransaction = ref.watch(isDrainTransactionProvider);

    return walletController.match(
      (error) =>
          Either<String, PartiallySignedTransaction>.left(error.toString()),
      (controller) {
        if (isDrainTransaction) {
          return controller
              .beginDrainTransaction(destination, asset, blockchain, amount)
              .run();
        } else {
          return controller
              .beginNewTransaction(destination, asset, blockchain, amount)
              .run();
        }
      },
    );
  },
);
