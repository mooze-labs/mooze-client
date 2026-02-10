import 'peg_transaction.dart';

/// Status of a peg-in/peg-out order
class PegOrderStatus {
  final String orderId;
  final bool isPegIn;
  final String address;
  final String receiveAddress;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<PegTransaction> transactions;

  PegOrderStatus({
    required this.orderId,
    required this.isPegIn,
    required this.address,
    required this.receiveAddress,
    required this.createdAt,
    this.expiresAt,
    required this.transactions,
  });

  factory PegOrderStatus.fromJson(Map<String, dynamic> json) {
    return PegOrderStatus(
      orderId: json['order_id'],
      isPegIn: json['peg_in'],
      address: json['addr'],
      receiveAddress: json['addr_recv'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      expiresAt:
          json['expires_at'] != 0
              ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'])
              : null,
      transactions:
          (json['list'] as List)
              .map((tx) => PegTransaction.fromJson(tx))
              .toList(),
    );
  }
}
