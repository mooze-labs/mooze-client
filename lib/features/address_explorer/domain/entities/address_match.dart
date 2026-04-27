import '../enums/address_chain.dart';
import '../enums/address_status.dart';

/// Result of an ownership probe for a single address.
///
/// When [isOwned] is false, the other fields carry no meaning.
class AddressMatch {
  final String address;
  final bool isOwned;
  final AddressChain? chain;
  final AddressStatus? status;
  final int? derivationIndex;

  const AddressMatch({
    required this.address,
    required this.isOwned,
    this.chain,
    this.status,
    this.derivationIndex,
  });

  const AddressMatch.notOwned(this.address)
    : isOwned = false,
      chain = null,
      status = null,
      derivationIndex = null;

  const AddressMatch.owned({
    required this.address,
    required AddressChain this.chain,
    required AddressStatus this.status,
    this.derivationIndex,
  }) : isOwned = true;
}
