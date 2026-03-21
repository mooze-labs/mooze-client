import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/address_generator_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class PixDepositController {
  final PixRepository _pixRepository;
  final AddressGeneratorRepository _addressRepository;

  PixDepositController(
    PixRepository pixRepository,
    AddressGeneratorRepository addrGenRepository,
  ) : _pixRepository = pixRepository,
      _addressRepository = addrGenRepository;

  TaskEither<String, PixDeposit> newDeposit(int amountInCents, Asset asset) {
    return _addressRepository.generateNewAddress().flatMap(
      (address) =>
          _pixRepository.newDeposit(amountInCents, address, asset: asset),
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
