import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../entities/address_match.dart';
import '../enums/address_chain.dart';
import '../repositories/address_explorer_repository.dart';
import '../services/address_chain_detector.dart';

/// Orchestrates ownership probing across both chains.
///
/// 1. Strips any payment-URI scheme.
/// 2. Detects candidate chains via [AddressChainDetector].
/// 3. Probes the repository for each candidate. The first ownership match
///    wins; if none claims the address, the use case returns
///    [AddressMatch.notOwned].
class FindAddress {
  final AddressExplorerRepository repository;
  final AddressChainDetector detector;

  const FindAddress(this.repository, this.detector);

  TaskEither<WalletError, AddressMatch> call(String input) {
    final cleaned = detector.stripUriScheme(input);
    if (cleaned.isEmpty) {
      return TaskEither.left(
        const WalletError(
          WalletErrorType.invalidAddress,
          'Endereço vazio',
        ),
      );
    }

    final candidates = detector.detect(cleaned);
    if (candidates.isEmpty) {
      return TaskEither.right(AddressMatch.notOwned(cleaned));
    }

    return _probe(cleaned, candidates, 0);
  }

  TaskEither<WalletError, AddressMatch> _probe(
    String address,
    List<AddressChain> candidates,
    int index,
  ) {
    if (index >= candidates.length) {
      return TaskEither.right(AddressMatch.notOwned(address));
    }
    final chain = candidates[index];
    final probe = chain == AddressChain.bitcoin
        ? repository.isOwnedBitcoinAddress(address)
        : repository.isOwnedLiquidAddress(address);

    return probe.flatMap((match) {
      if (match.isOwned) return TaskEither.right(match);
      return _probe(address, candidates, index + 1);
    });
  }
}
