import 'package:fpdart/fpdart.dart';

import '../../data/models.dart';

abstract class SwapRepository {
  TaskEither<String, List<SideswapAsset>> getAssets();
  TaskEither<String, List<SideswapMarket>> getMarkets();

  ({
    String baseAsset,
    String quoteAsset,
    SwapDirection direction,
    String assetType,
  })?
  normalizeSwapParams({
    required String sendAsset,
    required String receiveAsset,
  });

  /// Starts a quote subscription for [amount] of [sendAsset]. The core
  /// picks the market, the UTXOs and the receive address. Returns the
  /// quote stream, or the reason the subscription did not start.
  Future<Either<String, Stream<QuoteResponse>>> startQuote({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
  });

  /// Broadcast stream of every quote emission on the SideSwap WS,
  /// regardless of which subscription generated it. Exposed so the
  /// controller can attach a listener even when its own `startQuote`
  /// preflight (e.g. markets normalization) fails — incoming quotes
  /// from previously-opened subscriptions can still match the user's
  /// intent and be adopted as the active quote.
  Stream<QuoteResponse> get quoteStream;

  void stopQuote();

  Future<void> forceReconnect();

  /// Accepts a quote: the core fetches the PSET, signs it with the wallet
  /// and submits it. Returns the txid.
  TaskEither<String, String> executeSwap(int quoteId);

  void dispose();
}
