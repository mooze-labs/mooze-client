import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/swap/domain/entities.dart';
import '../datasources/sideswap.dart';
import '../models.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class SwapRepositoryImpl implements SwapRepository {
  final SideswapService sideswapService;
  final SwapWallet liquidWallet;

  SwapRepositoryImpl({
    required this.sideswapService,
    required this.liquidWallet,
  });

  @override
  TaskEither<String, List<SideswapAsset>> getAssets() => TaskEither.tryCatch(
    () async => await sideswapService.getAssets(),
    (e, _) => e.toString(),
  );

  @override
  TaskEither<String, List<SideswapMarket>> getMarkets() => TaskEither.tryCatch(
    () async => await sideswapService.getMarkets(),
    (e, _) => e.toString(),
  );

  @override
  Either<String, Stream<QuoteResponse>> startQuote({
    required String baseAsset,
    required String quoteAsset,
    required String assetType,
    required BigInt amount,
    required SwapDirection direction,
    required List<SwapUtxo> utxos,
    required String receiveAddress,
    required String changeAddress,
  }) {
    try {
      sideswapService.startQuote(
        baseAsset: baseAsset,
        quoteAsset: quoteAsset,
        assetType: assetType,
        amount: amount,
        direction: direction,
        utxos: utxos,
        receiveAddress: receiveAddress,
        changeAddress: changeAddress,
      );
      return Either.right(sideswapService.quoteResponseStream);
    } catch (e) {
      return Either.left(e.toString());
    }
  }

  @override
  void stopQuote() {
    sideswapService.stopQuotes();
  }

  @override
  TaskEither<String, String> getQuotePset(int quoteId) => TaskEither.tryCatch(
    () async => await sideswapService.getQuoteDetails(quoteId).then((pset) {
      if (pset == null) throw 'Quote pset não encontrado';
      return pset;
    }),
    (e, _) => e.toString(),
  );

  @override
  TaskEither<String, String> signAndBroadcast({
    required int quoteId,
    required String pset,
  }) {
    return liquidWallet
        .signSwapOperation(pset)
        .flatMap(
          (signed) => TaskEither.tryCatch(
            () async =>
                await sideswapService.signQuote(quoteId, signed).then((txid) {
                  if (txid == null) throw 'Falha ao assinar/enviar swap';
                  return txid;
                }),
            (e, _) => e.toString(),
          ),
        );
  }

  @override
  TaskEither<String, List<SwapUtxo>> selectUtxos({
    required String assetId,
    required BigInt amount,
  }) => liquidWallet.getUtxos(Asset.fromId(assetId), amount);

  @override
  TaskEither<String, String> getNewAddress() => TaskEither.tryCatch(
    () async => await liquidWallet.getAddress().run(),
    (e, _) => e.toString(),
  );
}
