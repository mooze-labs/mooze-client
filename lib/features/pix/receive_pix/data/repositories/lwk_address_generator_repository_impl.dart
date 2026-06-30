import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/address_generator_repository.dart';

/// Generates a Liquid receive address for the PIX flow via the V2
/// [WalletRepository] (which delegates to V2 Breez Liquid service).
class LwkAddressGeneratorRepositoryImpl implements AddressGeneratorRepository {
  final WalletRepository _walletRepository;

  LwkAddressGeneratorRepositoryImpl(WalletRepository walletRepository)
      : _walletRepository = walletRepository;

  @override
  TaskEither<String, String> generateNewAddress() {
    return TaskEither<String, String>(() async {
      final result = await _walletRepository.liquidReceiveAddress();
      return result.fold<Either<String, String>>(
        (err) => Either.left('Erro ao gerar endereço: ${err.toString()}'),
        (addr) {
          final address = addr.address;
          if (address == null || address.isEmpty) {
            return Either.left('Erro ao gerar endereço: empty address');
          }
          return Either.right(address);
        },
      );
    });
  }
}
