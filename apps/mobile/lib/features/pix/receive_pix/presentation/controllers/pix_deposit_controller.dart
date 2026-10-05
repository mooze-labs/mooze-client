import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class PixDepositController {
  final PixRepository _pixRepository;

  PixDepositController(PixRepository pixRepository)
      : _pixRepository = pixRepository;

  /// Creates a deposit that pays to a new Liquid wallet address. The core
  /// generates the address.
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    Asset asset, {
    String? taxIdNumber,
  }) {
    return _pixRepository.newDeposit(
      amountInCents,
      asset: asset,
      taxIdNumber: taxIdNumber,
    );
  }

  TaskEither<String, PixDeposit> getDeposit(String depositId) {
    return _pixRepository
        .getDeposit(depositId)
        .flatMap(
          (optionDeposit) => optionDeposit.fold(
            () =>
                TaskEither<String, PixDeposit>.left("Depósito não encontrado"),
            (deposit) => TaskEither.right(deposit),
          ),
        );
  }
}
