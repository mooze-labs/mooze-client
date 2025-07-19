class PixStatusUpdate {
  final String id;
  final String status;
  final String? blockchainTxid;

  PixStatusUpdate({
    required this.id,
    required this.status,
    this.blockchainTxid,
  });

  factory PixStatusUpdate.fromJson(Map<String, dynamic> json) {
    return PixStatusUpdate(
      id: json['id'] as String,
      status: json['status'] as String,
      blockchainTxid: json['blockchain_txid'] as String?,
    );
  }
}
