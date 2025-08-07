import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
import 'package:mooze_mobile/features/swap/domain/repositories.dart';

import '../models.dart';
import '../../domain/entities.dart';

class SwapRepositoryImpl extends SwapRepository {
  final SideswapService _sideswapService;
  final SwapWallet _liquidWallet;

  SwapRepositoryImpl({
    required SideswapService sideswapService,
    required SwapWallet liquidWallet,
  }) : _sideswapService = sideswapService,
       _liquidWallet = liquidWallet;

  @override
  TaskEither<String, double> getSwapRate(Asset sendAsset, Asset receiveAsset) {
    return _getMarket(sendAsset, receiveAsset).flatMap(
      (market) => TaskEither<String, (String, String)>.fromTask(
        _getAddresses(),
      ).flatMap(
        (addresses) =>
            _processRateQuote(sendAsset, receiveAsset, market, addresses),
      ),
    );
  }

  TaskEither<String, double> _processRateQuote(
    Asset sendAsset,
    Asset receiveAsset,
    SideswapMarket market,
    (String, String) addresses,
  ) {
    return TaskEither.tryCatch(() async {
      final (recvAddress, changeAddress) = addresses;

      _sideswapService.startQuote(
        baseAsset: market.baseAssetId,
        quoteAsset: market.quoteAssetId,
        assetType:
            (Asset.toId(sendAsset) == market.baseAssetId) ? 'Base' : 'Quote',
        amount: BigInt.from(10000000),
        direction: SwapDirection.sell,
        utxos: [],
        receiveAddress: recvAddress,
        changeAddress: changeAddress,
      );

      final quote = await _sideswapService.quoteResponseStream.first;

      if (quote.isError) {
        _sideswapService.stopQuotes();
        throw Exception(quote.error!.errorMessage);
      }

      if (quote.isLowBalance) {
        final baseAmount = quote.lowBalance!.baseAmount / pow(10, 8);
        final quoteAmount = quote.lowBalance!.quoteAmount / pow(10, 8);
        final rate = quoteAmount / baseAmount;
        _sideswapService.stopQuotes();
        return rate;
      }

      final baseAmount = quote.quote!.baseAmount / pow(10, 8);
      final quoteAmount = quote.quote!.quoteAmount / pow(10, 8);
      final rate = quoteAmount / baseAmount;
      _sideswapService.stopQuotes();
      return rate;
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, SwapOperation> startNewSwapOperation(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
  ) {
    return _getMarket(sendAsset, receiveAsset).flatMap(
      (market) => _getUtxos(sendAsset, sendAmount).flatMap(
        (utxos) => TaskEither<String, (String, String)>.fromTask(
          _getAddresses(),
        ).flatMap(
          (addresses) => _processQuote(
            sendAsset,
            receiveAsset,
            sendAmount,
            market,
            utxos,
            addresses,
          ),
        ),
      ),
    );
  }

  TaskEither<String, SwapOperation> _processQuote(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
    SideswapMarket market,
    List<SwapUtxo> utxos,
    (String, String) addresses,
  ) {
    return TaskEither.tryCatch(() async {
      final (recvAddress, changeAddress) = addresses;

      _sideswapService.startQuote(
        baseAsset: market.baseAssetId,
        quoteAsset: market.quoteAssetId,
        assetType:
            (Asset.toId(sendAsset) == market.baseAssetId) ? 'Base' : 'Quote',
        amount: sendAmount,
        direction: SwapDirection.sell,
        utxos: utxos,
        receiveAddress: recvAddress,
        changeAddress: changeAddress,
      );

      final quote = await _sideswapService.quoteResponseStream.first;

      if (quote.isError) {
        _sideswapService.stopQuotes();
        throw Exception(quote.error!.errorMessage);
      }

      if (quote.isLowBalance) {
        _sideswapService.stopQuotes();
        throw Exception("Insufficient balance.");
      }

      _sideswapService.stopQuotes();
      return SwapOperation(
        id: quote.quote!.quoteId,
        sendAsset: Asset.toId(sendAsset),
        receiveAsset: Asset.toId(receiveAsset),
        sendAmount: sendAmount,
        receiveAmount:
            (Asset.toId(receiveAsset) == market.quoteAssetId)
                ? BigInt.from(quote.quote!.quoteAmount)
                : BigInt.from(quote.quote!.baseAmount),
        ttl: quote.quote!.ttl,
      );
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, String> confirmSwap(SwapOperation operation) {
    return TaskEither.tryCatch(() async {
          final swapPset = await _sideswapService.getQuoteDetails(operation.id);
          if (swapPset == null) {
            throw Exception(
              "Provedor indisponível. Tente novamente mais tarde.",
            );
          }

          return swapPset;
        }, (error, stackTrace) => "Erro ao obter detalhes da cotação: $error")
        .flatMap((swapPset) => _liquidWallet.signSwapOperation(swapPset))
        .flatMap(
          (signedPset) => TaskEither.tryCatch(() async {
            final txid = await _sideswapService.signQuote(
              operation.id,
              signedPset,
            );
            if (txid == null) {
              throw Exception("Falha no dealer. Tente novament mais tarde.");
            }
            return txid;
          }, (error, stackTrace) => "Erro ao finalizar swap: $error"),
        );
  }

  TaskEither<String, List<SwapUtxo>> _getUtxos(Asset asset, BigInt sendAmount) {
    return _liquidWallet.getUtxos(asset, sendAmount);
  }

  Task<(String, String)> _getAddresses() {
    return Task(() async {
      final recvAddress = await _liquidWallet.getAddress().run();
      final changeAddress = await _liquidWallet.getAddress().run();
      return (recvAddress, changeAddress);
    });
  }

  TaskEither<String, SideswapMarket> _getMarket(
    Asset sendAsset,
    Asset receiveAsset,
  ) {
    return TaskEither.tryCatch(() async {
      final markets = await _sideswapService.getMarkets();
      final market = markets.firstWhere(
        (m) =>
            m.baseAssetId == Asset.toId(sendAsset) &&
                m.quoteAssetId == Asset.toId(receiveAsset) ||
            m.baseAssetId == Asset.toId(receiveAsset) &&
                m.quoteAssetId == Asset.toId(sendAsset),
      );
      return market;
    }, (error, stackTrace) => error.toString());
  }
}
