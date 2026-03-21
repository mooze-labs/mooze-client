import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/infra/lwk/wallet.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/address_generator_repository.dart';

class LwkAddressGeneratorRepositoryImpl implements AddressGeneratorRepository {
  final LiquidDataSource _wallet;

  LwkAddressGeneratorRepositoryImpl(LiquidDataSource wallet) : _wallet = wallet;

  @override
  TaskEither<String, String> generateNewAddress() {
    return TaskEither.tryCatch(
      () async => _wallet.getAddress(),
      (error, stackTrace) => "Erro ao gerar endereço: $error",
    );
  }
}
