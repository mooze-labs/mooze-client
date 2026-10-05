class TransactionStatusEvent {
  final String transactionId;
  final String assetId;
  final String assetTicker;
  final BigInt amount;
  final DateTime confirmedAt;

  TransactionStatusEvent({
    required this.transactionId,
    required this.assetId,
    required this.assetTicker,
    required this.amount,
    required this.confirmedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionStatusEvent &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}
