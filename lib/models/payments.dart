class PixTransaction {
  final String address;
  final String asset;
  final int brlAmount; // amount in cents

  PixTransaction({
    required this.address,
    required this.asset,
    required this.brlAmount,
  });
}

class PixTransactionResponse {
  final String qrCopyPaste;
  final String qrImageUrl;
  final String id;

  PixTransactionResponse({
    required this.qrCopyPaste,
    required this.qrImageUrl,
    required this.id,
  });
}
