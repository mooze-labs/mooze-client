import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../entities/wallet_address.dart';
import '../enums/address_chain.dart';
import '../repositories/address_explorer_repository.dart';

class ListAddresses {
  final AddressExplorerRepository repository;

  const ListAddresses(this.repository);

  TaskEither<WalletError, List<WalletAddress>> call({
    required AddressChain chain,
    int limit = 100,
  }) {
    switch (chain) {
      case AddressChain.bitcoin:
        return repository.listBitcoinAddresses(limit: limit);
      case AddressChain.liquid:
        return repository.listLiquidAddresses(limit: limit);
    }
  }
}
