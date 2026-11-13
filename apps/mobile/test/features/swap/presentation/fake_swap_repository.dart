import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/swap/data/models.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';

/// SideSwap, with the markets of the test and a quote stream that the test
/// feeds by hand.
class FakeSwapRepository implements SwapRepository {
  FakeSwapRepository(this.markets);

  final List<SideswapMarket> markets;
  final quotes = StreamController<QuoteResponse>.broadcast();

  /// The quote ids that were signed, in order.
  final signed = <int>[];

  /// As the real repository, it knows the markets once it has loaded them.
  bool _marketsLoaded = false;

  @override
  TaskEither<String, List<SideswapAsset>> getAssets() =>
      TaskEither.right(const []);

  @override
  TaskEither<String, List<SideswapMarket>> getMarkets() {
    _marketsLoaded = true;
    return TaskEither.right(markets);
  }

  @override
  ({
    String baseAsset,
    String quoteAsset,
    SwapDirection direction,
    String assetType,
  })?
  normalizeSwapParams({
    required String sendAsset,
    required String receiveAsset,
  }) {
    if (!_marketsLoaded) return null;
    for (final m in markets) {
      if (m.baseAssetId == sendAsset && m.quoteAssetId == receiveAsset) {
        return (
          baseAsset: sendAsset,
          quoteAsset: receiveAsset,
          direction: SwapDirection.sell,
          assetType: 'Base',
        );
      }
      if (m.baseAssetId == receiveAsset && m.quoteAssetId == sendAsset) {
        return (
          baseAsset: receiveAsset,
          quoteAsset: sendAsset,
          direction: SwapDirection.sell,
          assetType: 'Quote',
        );
      }
    }
    return null;
  }

  @override
  Future<Either<String, Stream<QuoteResponse>>> startQuote({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
  }) async => right(quotes.stream);

  @override
  Stream<QuoteResponse> get quoteStream => quotes.stream;

  @override
  void stopQuote() {}

  @override
  Future<void> forceReconnect() async {}

  @override
  TaskEither<String, String> executeSwap(int quoteId) {
    signed.add(quoteId);
    return TaskEither.right('signed');
  }

  @override
  void dispose() {}
}

/// A market of [base]/[quote], with the fees in [feeAsset] ("Base" or
/// "Quote").
SideswapMarket market({
  required String base,
  required String quote,
  required String feeAsset,
}) => SideswapMarket(
  baseAssetId: base,
  quoteAssetId: quote,
  feeAsset: feeAsset,
  type: 'Stablecoin',
);

/// A quote of the market [base]/[quote], before fees. The fees are those
/// of the swap of the report: 2 282 sats.
QuoteResponse quoteOf({
  required int id,
  required String base,
  required String quote,
  required int requested,
  required int baseAmount,
  required int quoteAmount,
}) => QuoteResponse(
  quote: SideswapQuote(
    quoteId: id,
    baseAmount: baseAmount,
    quoteAmount: quoteAmount,
    serverFee: 2202,
    fixedFee: 80,
    ttl: 30000,
  ),
  baseAssetId: base,
  quoteAssetId: quote,
  requestedAmount: requested,
);
