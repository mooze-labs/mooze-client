import 'dart:convert';

class PendingTransaction {
  final String id;
  final String assetId;
  final String assetTicker;
  final BigInt amount;
  final DateTime detectedAt;

  PendingTransaction({
    required this.id,
    required this.assetId,
    required this.assetTicker,
    required this.amount,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'assetTicker': assetTicker,
      'amount': amount.toString(),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      assetTicker: json['assetTicker'] as String,
      amount: BigInt.parse(json['amount'] as String),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PendingTransaction.fromJsonString(String jsonString) {
    return PendingTransaction.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
