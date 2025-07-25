class PaymentDetail {
  final String label;
  final String value;

  const PaymentDetail({required this.label, required this.value});

  static const List<PaymentDetail> paymentDetails = [
    PaymentDetail(label: 'Valor R\$', value: '50,00'),
    PaymentDetail(label: 'Cotação', value: '1'),
    PaymentDetail(label: 'Quantidade', value: '48 DEPIX'),
    PaymentDetail(label: 'Taxa', value: '3,5%'),
    PaymentDetail(label: 'Endereço', value: 'lqq.fvd4r'),
  ];
}
