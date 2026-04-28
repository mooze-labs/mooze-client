import '../enums/address_chain.dart';

/// Represents a single unspent output associated with a wallet address.
///
/// On Bitcoin this maps directly to a UTXO (txid:vout + value).
/// On Liquid the SDKs do not expose individual UTXOs to the app layer; the
/// closest proxy is a per-asset balance entry, so [outpoint] is empty and
/// [assetId] identifies the asset.
class AddressUtxo {
  final String address;
  final AddressChain chain;
  final String outpoint;
  final BigInt value;
  final String? assetId;
  final bool confirmed;

  const AddressUtxo({
    required this.address,
    required this.chain,
    required this.outpoint,
    required this.value,
    this.assetId,
    this.confirmed = true,
  });
}
