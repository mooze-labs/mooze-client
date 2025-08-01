class PaymentDetail {
  final String label;
  final String value;

  const PaymentDetail({required this.label, required this.value});

  static const List<PaymentDetail> paymentDetails = [
    PaymentDetail(label: 'Rede', value: 'onchain'),
    PaymentDetail(label: 'Cotação', value: '115.000'),
    PaymentDetail(label: 'Taxa', value: '240 sats'),
  ];
}
