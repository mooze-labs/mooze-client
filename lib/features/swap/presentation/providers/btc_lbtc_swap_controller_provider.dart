import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import '../controllers/btc_lbtc_swap_controller.dart';

final btcLbtcSwapControllerProvider =
    FutureProvider<Either<String, BtcLbtcSwapController>>((ref) async {
      final walletControllerEither = await ref.read(
        walletControllerProvider.future,
      );

      return walletControllerEither.bimap(
        (error) => 'Erro ao carregar wallet: ${error.description}',
        (walletController) => BtcLbtcSwapController(walletController),
      );
    });
