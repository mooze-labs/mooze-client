import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../entities/wallet_address.dart';
import '../enums/address_chain.dart';
import '../repositories/address_explorer_repository.dart';

class GetNextUnusedAddress {
  final AddressExplorerRepository repository;

  const GetNextUnusedAddress(this.repository);

  TaskEither<WalletError, WalletAddress> call(AddressChain chain) {
    switch (chain) {
      case AddressChain.bitcoin:
        return repository.getNextUnusedBitcoinAddress();
      case AddressChain.liquid:
        return repository.getNextUnusedLiquidAddress();
    }
  }
}
