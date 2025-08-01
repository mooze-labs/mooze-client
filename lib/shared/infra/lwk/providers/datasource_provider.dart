import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

import '../wallet/datasource.dart';
import 'electrum_node_provider.dart';
import 'network_provider.dart';

final liquidDataSourceProvider =
    FutureProvider<Either<String, LiquidDataSource>>((ref) async {
      final electrumNodeUrl = ref.read(electrumNodeProvider);
      final network = ref.read(networkProvider);
      final mnemonic = ref.read(mnemonicStoreProvider).getMnemonic();

      final TaskEither<String, String> descriptor = mnemonic.flatMap(
        (mnemonicOption) => mnemonicOption.fold(
          () =>
              TaskEither<String, String>.left("Mnemonic has not been defined."),
          (mnemonic) => deriveNewDescriptorFromMnemonic(
            mnemonic,
            network,
          ).flatMap((descriptor) => TaskEither.right(descriptor.ctDescriptor)),
        ),
      );

      return descriptor
          .flatMap(
            (descriptor) => initializeNewWallet(descriptor, network).flatMap(
              (wallet) => electrumNodeUrl.flatMap(
                (url) => TaskEither<String, LiquidDataSource>.right(
                  LiquidDataSource(
                    wallet: wallet,
                    electrumUrl: url,
                    network: network,
                    validateDomain: true,
                  ),
                ),
              ),
            ),
          )
          .run();
    });
