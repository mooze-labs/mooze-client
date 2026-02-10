/// PayJoin UTXO details
class PayJoinUtxo {
  final String txid;
  final int vout;
  final String scriptPubKey;
  final String assetId;
  final int value;
  final String assetBf;
  final String valueBf;
  final String assetCommitment;
  final String valueCommitment;

  PayJoinUtxo({
    required this.txid,
    required this.vout,
    required this.scriptPubKey,
    required this.assetId,
    required this.value,
    required this.assetBf,
    required this.valueBf,
    required this.assetCommitment,
    required this.valueCommitment,
  });

  factory PayJoinUtxo.fromJson(Map<String, dynamic> json) {
    return PayJoinUtxo(
      txid: json['txid'],
      vout: json['vout'],
      scriptPubKey: json['script_pub_key'],
      assetId: json['asset_id'],
      value: json['value'],
      assetBf: json['asset_bf'],
      valueBf: json['value_bf'],
      assetCommitment: json['asset_commitment'],
      valueCommitment: json['value_commitment'],
    );
  }
}
