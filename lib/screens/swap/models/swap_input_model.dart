import 'package:mooze_mobile/models/assets.dart';

class SwapInputModel {
  Asset sendAsset;
  Asset recvAsset;
  int sendAssetSatoshiAmount;
  int recvAssetSatoshiAmount;

  SwapInputModel({
    required this.sendAsset,
    required this.recvAsset,
    required this.sendAssetSatoshiAmount,
    required this.recvAssetSatoshiAmount,
  });

  SwapInputModel copyWith({
    Asset? sendAsset,
    Asset? recvAsset,
    int? sendAssetSatoshiAmount,
    int? recvAssetSatoshiAmount,
  }) {
    return SwapInputModel(
      sendAsset: sendAsset ?? this.sendAsset,
      recvAsset: recvAsset ?? this.recvAsset,
      sendAssetSatoshiAmount:
          sendAssetSatoshiAmount ?? this.sendAssetSatoshiAmount,
      recvAssetSatoshiAmount:
          recvAssetSatoshiAmount ?? this.recvAssetSatoshiAmount,
    );
  }
}