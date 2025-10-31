import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class BtcLbtcSwapController {
  final WalletController _walletController;

  BtcLbtcSwapController(this._walletController);

  static const int minSwapAmount = 25000;

  TaskEither<String, Transaction> executePegIn(BigInt amount) {
    if (amount < BigInt.from(minSwapAmount)) {
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    return _walletController
        .beginNewTransaction(
          '',
          Asset.btc,
          Blockchain.bitcoin,
          amount,
        )
        .mapLeft((error) => 'Erro ao preparar peg-in: $error')
        .flatMap(
          (psbt) => _walletController
              .confirmTransaction(psbt)
              .mapLeft((error) => 'Erro ao enviar peg-in: $error'),
        );
  }

  TaskEither<String, Transaction> executePegOut(BigInt amount) {
    if (amount < BigInt.from(minSwapAmount)) {
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    return _walletController
        .beginNewTransaction(
          '',
          Asset.lbtc,
          Blockchain.liquid,
          amount,
        )
        .mapLeft((error) => 'Erro ao preparar peg-out: $error')
        .flatMap(
          (psbt) => _walletController
              .confirmTransaction(psbt)
              .mapLeft((error) => 'Erro ao enviar peg-out: $error'),
        );
  }

  bool isValidAmount(BigInt? amount) {
    if (amount == null) return false;
    return amount >= BigInt.from(minSwapAmount);
  }

  String formatSatsToBtc(BigInt sats) {
    final btc = sats.toDouble() / 100000000;
    return btc.toStringAsFixed(8);
  }
}
