/// Details for a given transaction returned by /transaction/statuses
class PixTransactionDetails {
  final String id;
  final String status;
  final int amountInCents;
  final String? blockchainTxid;
  final int? assetAmount;

  PixTransactionDetails({
    required this.id,
    required this.status,
    required this.amountInCents,
    this.blockchainTxid,
    this.assetAmount,
  });

  factory PixTransactionDetails.fromJson(Map<String, dynamic> json) {
    return PixTransactionDetails(
      id: json['id'],
      status: json['status'],
      amountInCents: json['amount_in_cents'],
      blockchainTxid: json['blockchain_txid'],
      assetAmount: json['asset_amount'],
    );
  }
}
