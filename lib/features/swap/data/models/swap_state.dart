import '../../../../models/assets.dart';
import 'swap_direction.dart';
import 'sideswap_quote.dart';

/// Current state of a swap operation
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
