class PaymentLimits {
  final BigInt minSat;
  final BigInt maxSat;

  const PaymentLimits({required this.minSat, required this.maxSat});

  double get minBtc => minSat.toDouble() / 100000000;
  double get maxBtc => maxSat.toDouble() / 100000000;

  @override
  String toString() {
    return 'PaymentLimits(minSat: $minSat, maxSat: $maxSat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentLimits &&
        other.minSat == minSat &&
        other.maxSat == maxSat;
  }

  @override
  int get hashCode => minSat.hashCode ^ maxSat.hashCode;
}

class OnchainPaymentLimitsResponse {
  final PaymentLimits receive;
  final PaymentLimits send;

  const OnchainPaymentLimitsResponse({
    required this.receive,
    required this.send,
  });

  @override
  String toString() {
    return 'OnchainPaymentLimitsResponse(receive: $receive, send: $send)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnchainPaymentLimitsResponse &&
        other.receive == receive &&
        other.send == send;
  }

  @override
  int get hashCode => receive.hashCode ^ send.hashCode;
}

class LightningPaymentLimitsResponse {
  final PaymentLimits receive;
  final PaymentLimits send;

  const LightningPaymentLimitsResponse({
    required this.receive,
    required this.send,
  });

  @override
  String toString() {
    return 'LightningPaymentLimitsResponse(receive: $receive, send: $send)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LightningPaymentLimitsResponse &&
        other.receive == receive &&
        other.send == send;
  }

  @override
  int get hashCode => receive.hashCode ^ send.hashCode;
}
