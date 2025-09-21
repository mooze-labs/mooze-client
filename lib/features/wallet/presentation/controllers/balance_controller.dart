import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class BalanceController {
  final WalletRepository _wallet;

  BalanceController(WalletRepository wallet) : _wallet = wallet;

  TaskEither<WalletError, BigInt> getAssetBalance(Asset asset) {
    return _wallet.getBalance().flatMap(
      (balance) => TaskEither.right(balance[asset] ?? BigInt.zero),
    );
  }
}
