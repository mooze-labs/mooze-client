import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/repositories.dart';
import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class PixDepositController {
  final PixRepository _pixRepository;
  final AddressGeneratorRepository _addressRepository;

  PixDepositController(PixRepository pixRepository, AddressGeneratorRepository addrGenRepository)
      : _pixRepository = pixRepository, _addressRepository = addrGenRepository;

  TaskEither<String, PixDeposit> newDeposit(int amountInCents, Asset asset) {
    return _addressRepository.generateNewAddress()
        .flatMap(
          (address) => _pixRepository.newDeposit(amountInCents, address, asset: asset)
    );
  }

  TaskEither<String, PixDeposit> getDeposit(String depositId) {
    return _pixRepository.getDeposit(depositId).flatMap(
        (optionDeposit) => optionDeposit.fold(
            () => TaskEither<String, PixDeposit>.left("Depósito não encontrado"),
            (deposit) => TaskEither.right(deposit))
    );
  }
}