/// Response from creating a new peg-in/peg-out order
class PegOrderResponse {
  final String orderId;
  final String pegAddress;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? receiveAmount;

  PegOrderResponse({
    required this.orderId,
    required this.pegAddress,
    required this.createdAt,
    this.expiresAt,
    this.receiveAmount,
  });

  factory PegOrderResponse.fromJson(Map<String, dynamic> json) {
    return PegOrderResponse(
      orderId: json['order_id'],
      pegAddress: json['peg_addr'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      expiresAt:
          json['expires_at'] != 0
              ? DateTime.fromMillisecondsSinceEpoch(json['expires_at'])
              : null,
      receiveAmount: json['recv_amount'],
    );
  }
}
