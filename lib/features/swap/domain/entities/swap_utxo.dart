/// UTXO used in swap transactions
class SwapUtxo {
  final String txid;
  final int vout;
  final String asset;
  final String assetBf; // asset blinding factor
  final BigInt value;
  final String valueBf; // value blinding factor
  final String? redeemScript;

  SwapUtxo({
    required this.txid,
    required this.vout,
    required this.asset,
    required this.assetBf,
    required this.value,
    required this.valueBf,
    this.redeemScript,
  });

  Map<String, dynamic> toJson() {
    return {
      'txid': txid,
      'vout': vout,
      'asset': asset,
      'asset_bf': assetBf,
      'value': value.toInt(),
      'value_bf': valueBf,
      'redeem_script': redeemScript,
    };
  }
}
