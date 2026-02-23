class PixDepositResponse {
  final String depositId;
  final String qrCopyPaste;
  final String qrImageUrl;

  PixDepositResponse({
    required this.depositId,
    required this.qrCopyPaste,
    required this.qrImageUrl,
  });

  factory PixDepositResponse.fromJson(Map<String, dynamic> json) {
    return PixDepositResponse(
      depositId: json['transaction_id'] as String,
      qrCopyPaste: json['qr_copy_paste'] as String,
      qrImageUrl: json['qr_image_url'] as String,
    );
  }
}
