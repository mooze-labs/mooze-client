import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/blockchain_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/network_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/wallet.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

final bdkDatasourceProvider = FutureProvider<Either<String, BdkDataSource>>((
  ref,
) async {
  final blockchain = ref.read(blockchainProvider);
  final maybeMnemonic = ref.read(mnemonicStoreProvider).getMnemonic();
  final network = ref.read(networkProvider);

  final mnemonic = maybeMnemonic.flatMap(
    (opt) => opt.fold(
      () => TaskEither<String, String>.left("Mnemonic has not been defined"),
      (mnemonic) => TaskEither<String, String>.right(mnemonic),
    ),
  );

  final wallet = mnemonic.flatMap((m) => setupWallet(m, network));
  final dataSource = wallet.flatMap(
    (w) => blockchain.flatMap(
      (b) => TaskEither.right(BdkDataSource(wallet: w, blockchain: b)),
    ),
  );

  return dataSource.run();
});
