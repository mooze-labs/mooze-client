import 'pay_join_utxo.dart';

/// Response from starting a PayJoin transaction
class PayJoinStartResponse {
  final String orderId;
  final DateTime expiresAt;
  final double price;
  final int fixedFee;
  final String feeAddress;
  final String changeAddress;
  final List<PayJoinUtxo> utxos;

  PayJoinStartResponse({
    required this.orderId,
    required this.expiresAt,
    required this.price,
    required this.fixedFee,
    required this.feeAddress,
    required this.changeAddress,
    required this.utxos,
  });

  factory PayJoinStartResponse.fromJson(Map<String, dynamic> json) {
    return PayJoinStartResponse(
      orderId: json['order_id'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at']),
      price: json['price'],
      fixedFee: json['fixed_fee'],
      feeAddress: json['fee_address'],
      changeAddress: json['change_address'],
      utxos:
          (json['utxos'] as List)
              .map((utxo) => PayJoinUtxo.fromJson(utxo))
              .toList(),
    );
  }
}
