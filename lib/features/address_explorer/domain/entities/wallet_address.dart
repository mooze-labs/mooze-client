import '../enums/address_chain.dart';
import '../enums/address_status.dart';
import 'address_utxo.dart';

class WalletAddress {
  final String address;
  final AddressChain chain;
  final AddressStatus status;
  final int derivationIndex;
  final BigInt receivedSats;
  final List<AddressUtxo> utxos;

  WalletAddress({
    required this.address,
    required this.chain,
    required this.status,
    required this.derivationIndex,
    BigInt? receivedSats,
    this.utxos = const [],
  }) : receivedSats = receivedSats ?? BigInt.zero;

  bool get isUsed => status == AddressStatus.used;
  bool get isUnused => status == AddressStatus.unused;
}
