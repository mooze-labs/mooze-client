import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/models/assets.dart';

class SwapQuoteModel {
  final Asset sendAsset;
  final Asset recvAsset;
  final AssetPair assetPair;
  final QuoteResponse quoteResponse;
  final SwapDirection direction;
  final AssetType assetType;

  SwapQuoteModel({
    required this.sendAsset,
    required this.recvAsset,
    required this.assetPair,
    required this.quoteResponse,
    required this.direction,
    required this.assetType,
  });
}
