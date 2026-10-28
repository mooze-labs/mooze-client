/// How the merchant charges a confirmed sale amount.
enum MerchantPaymentMethod {
  /// A Pix QR Code. The flow asks for the payer's CPF first.
  pixQrCode,

  /// A payment link that the payer opens in a browser. The flow does not
  /// open the CPF step of the QR Code flow.
  paymentLink,
}
