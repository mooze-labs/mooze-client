import 'package:fpdart/fpdart.dart';

import '../../data/models.dart';
import '../entities.dart';

abstract class SwapRepository {
  TaskEither<String, List<SideswapAsset>> getAssets();
  TaskEither<String, List<SideswapMarket>> getMarkets();
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
  void stopQuote();
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
