import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/bitcoin.dart';

import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/breez.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl/liquid.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';

final walletRepositoryProvider = FutureProvider<
  Either<WalletError, WalletRepository>
>((ref) async {
  final breez = await ref.read(breezClientProvider.future);
  final breezWallet = breez.flatMap((b) => right(BreezWallet(b)));

  final liquidDatasource = await ref.watch(liquidDataSourceProvider.future);
  final liquidWallet = liquidDatasource.flatMap((l) => right(LiquidWallet(l)));

  final bdkDatasource = await ref.watch(bdkDatasourceProvider.future);
  final bitcoinWallet = bdkDatasource.flatMap((b) => right(BitcoinWallet(b)));

  final walletRepo = breezWallet.flatMap(
    (breez) => liquidWallet.flatMap(
      (liquid) => bitcoinWallet.flatMap(
        (bitcoin) => Either.right(WalletRepositoryImpl(breez, bitcoin, liquid)),
      ),
    ),
  );

  return walletRepo.fold(
    (err) => Either.left(WalletError(WalletErrorType.sdkError, err.toString())),
    (repo) => Either.right(repo),
  );
});
