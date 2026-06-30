import 'package:fpdart/fpdart.dart';

import '../../data/models.dart';
import '../entities.dart';

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

  Either<String, Stream<QuoteResponse>> startQuote({
    required String baseAsset,
    required String quoteAsset,
    required String assetType,
    required BigInt amount,
    required SwapDirection direction,
    required List<SwapUtxo> utxos,
    required String receiveAddress,
    required String changeAddress,
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

  void resetQuoteProgress();

  TaskEither<String, String> getQuotePset(int quoteId);
  TaskEither<String, String> signAndBroadcast({
    required int quoteId,
    required String pset,
  });
  TaskEither<String, List<SwapUtxo>> selectUtxos({
    required String assetId,
    required BigInt amount,
  });
  TaskEither<String, String> getNewAddress();
}
