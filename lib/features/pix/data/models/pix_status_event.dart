class PixStatusEvent {
  String depositId;
  String status;
  String? blockchainTxid;
  int? assetAmount;
  String? errorMessage;

  PixStatusEvent({
    required this.depositId,
    required this.status,
    this.blockchainTxid,
    this.assetAmount,
    this.errorMessage,
  });

  factory PixStatusEvent.fromJson(Map<String, dynamic> json) {
    return PixStatusEvent(
      depositId: json["transaction_id"] as String,
      status: json["status"] as String,
      blockchainTxid: json["blockchain_txid"] as String?,
      assetAmount: json["asset_amount"] as int?,
      errorMessage: json["error_message"] as String?,
    );
  }
}
