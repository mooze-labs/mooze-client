import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';

final walletRepositoryProvider =
    FutureProvider<Either<WalletError, LiquidWalletRepository>>((ref) async {
      final breez = await ref.read(breezClientProvider.future);

      return breez.fold(
        (err) => Either.left(
          WalletError(
            WalletErrorType.networkError,
            "Failed to instantiate Breez client: $err",
          ),
        ),
        (client) => Either.right(BreezWalletRepositoryImpl(client)),
      );
    });
