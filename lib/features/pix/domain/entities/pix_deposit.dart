class PixDeposit {
  final String id;
  final String qrCopyPaste;
  final String qrImageUrl;

  PixDeposit({
    required this.id,
    required this.qrCopyPaste,
    required this.qrImageUrl,
  });

  factory PixDeposit.fromJson(Map<String, dynamic> json) {
    return PixDeposit(
      id: json['transaction_id'] as String,
      qrCopyPaste: json['qr_copy_paste'] as String,
      qrImageUrl: json['qr_image_url'] as String,
    );
  }
}
