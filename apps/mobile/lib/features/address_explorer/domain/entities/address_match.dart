import '../enums/address_chain.dart';
import '../enums/address_status.dart';
import 'address_utxo.dart';

/// Result of an ownership probe for a single address.
///
/// When [isOwned] is false, the other fields carry no meaning.
class AddressMatch {
  final String address;
  final bool isOwned;
  final AddressChain? chain;
  final AddressStatus? status;
  final int? derivationIndex;
  final List<AddressUtxo> utxos;

  const AddressMatch({
    required this.address,
    required this.isOwned,
    this.chain,
    this.status,
    this.derivationIndex,
    this.utxos = const [],
  });

  const AddressMatch.notOwned(this.address)
    : isOwned = false,
      chain = null,
      status = null,
      derivationIndex = null,
      utxos = const [];

  const AddressMatch.owned({
    required this.address,
    required AddressChain this.chain,
    required AddressStatus this.status,
    this.derivationIndex,
    this.utxos = const [],
  }) : isOwned = true;

  /// Number of unspent outputs held by this address.
  int get utxoCount => utxos.length;
}
