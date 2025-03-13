// lib/models/sideswap.dart
import 'package:mooze_mobile/models/assets.dart';

enum SwapDirection { buy, sell }

class SideswapMarket {
  final String baseAssetId;
  final String quoteAssetId;
  final String feeAsset; // "Base" or "Quote"
  final String type; // "Stablecoin", "Amp", "Token"

  SideswapMarket({
    required this.baseAssetId,
    required this.quoteAssetId,
    required this.feeAsset,
    required this.type,
  });

  factory SideswapMarket.fromJson(Map<String, dynamic> json) {
    final assetPair = json['asset_pair'];
    return SideswapMarket(
      baseAssetId: assetPair['base'],
      quoteAssetId: assetPair['quote'],
      feeAsset: json['fee_asset'],
      type: json['type'],
    );
  }
}

class SideswapQuote {
  final int quoteId;
  final int baseAmount;
  final int quoteAmount;
  final int serverFee;
  final int fixedFee;
  final int ttl;

  SideswapQuote({
    required this.quoteId,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
    required this.ttl,
  });

  factory SideswapQuote.fromJson(Map<String, dynamic> json) {
    final success = json['status']['Success'];
    return SideswapQuote(
      quoteId: success['quote_id'],
      baseAmount: success['base_amount'],
      quoteAmount: success['quote_amount'],
      serverFee: success['server_fee'],
      fixedFee: success['fixed_fee'],
      ttl: success['ttl'],
    );
  }
}

class SwapState {
  final Asset? fromAsset;
  final Asset? toAsset;
  final double? amount;
  final SwapDirection direction;
  final SideswapQuote? quote;
  final bool isSubmitting;

  SwapState({
    this.fromAsset,
    this.toAsset,
    this.amount,
    this.direction = SwapDirection.sell,
    this.quote,
    this.isSubmitting = false,
  });

  SwapState copyWith({
    Asset? fromAsset,
    Asset? toAsset,
    double? amount,
    SwapDirection? direction,
    SideswapQuote? quote,
    bool? isSubmitting,
  }) {
    return SwapState(
      fromAsset: fromAsset ?? this.fromAsset,
      toAsset: toAsset ?? this.toAsset,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      quote: quote ?? this.quote,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
