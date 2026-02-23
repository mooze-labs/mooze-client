import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import '../controllers/btc_lbtc_swap_controller.dart';

const _tag = 'Swap';

final btcLbtcSwapControllerProvider = FutureProvider<
  Either<String, BtcLbtcSwapController>
>((ref) async {
  final log = AppLoggerService();

  log.debug(_tag, 'Initializing BtcLbtcSwapController provider');

  final walletControllerEither = await ref.read(
    walletControllerProvider.future,
  );

  return walletControllerEither.bimap(
    (error) {
      log.error(
        _tag,
        'Failed to load wallet controller for BtcLbtc swap: ${error.description}',
      );
      return 'Erro ao carregar wallet: ${error.description}';
    },
    (walletController) {
      log.info(_tag, 'BtcLbtcSwapController initialized successfully');
      return BtcLbtcSwapController(walletController);
    },
  );
});
