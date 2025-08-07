enum Network { bitcoin, liquid, lightning }

class ReceiveCryptoInput {
  Network network;
  int? recvAmount;
  String? assetId;
  String? description;

  ReceiveCryptoInput({
    required this.network,
    this.recvAmount,
    this.assetId,
    this.description,
  });

  ReceiveCryptoInput copyWith({
    Network? network,
    int? recvAmount,
    String? assetId,
    String? description,
  }) {
    return ReceiveCryptoInput(
      network: network ?? this.network,
      recvAmount: recvAmount ?? this.recvAmount,
      assetId: assetId ?? this.assetId,
      description: description ?? this.description,
    );
  }
}
