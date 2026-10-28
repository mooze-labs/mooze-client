/// How the payer supplies the destination of a Pix payment.
enum PixSendMethod {
  /// The payer types a Pix key.
  key,

  /// The payer scans a QR Code.
  qrCode,

  /// The payer pastes a Copy and Paste code.
  copyPaste,

  /// The payer picks someone from the recent recipients list.
  recent,
}
