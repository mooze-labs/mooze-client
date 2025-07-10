import 'package:mooze_mobile/core/entities/asset.dart';
import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
import 'package:mooze_mobile/features/swap/data/datasources/wallet.dart';
import 'package:mooze_mobile/features/swap/domain/swap_repository.dart';

import '../data/models.dart';
import '../domain/entities/swap_operation.dart';

class SwapRepositoryImpl extends SwapRepository {
  final SideswapService _sideswapService;
  final LiquidWallet _liquidWallet;

  SwapRepositoryImpl({
    required SideswapService sideswapService,
    required LiquidWallet liquidWallet,
  }) : _sideswapService = sideswapService,
       _liquidWallet = liquidWallet;

  @override
  Future<double> getSwapRate(Asset sendAsset, Asset receiveAsset) async {
    final futures = <Future<String>>[
      _liquidWallet.getAddress(),
      _liquidWallet.getAddress(),
    ];
    final (recvAddress, changeAddress) =
        await Future.wait<String>(futures) as (String, String);

    final market = await _getMarket(sendAsset, receiveAsset);

    _sideswapService.startQuote(
      baseAsset: market.baseAssetId,
      quoteAsset: market.quoteAssetId,
      assetType:
          (Asset.toId(sendAsset) == market.baseAssetId) ? 'Base' : 'Quote',
      amount: BigInt.zero,
      direction: SwapDirection.sell,
      utxos: [],
      receiveAddress: recvAddress,
      changeAddress: changeAddress,
    );

    final quote = await _sideswapService.quoteResponseStream.single;
    if (quote.isError) {
      throw Exception(quote.error!.errorMessage);
    }

    if (quote.isLowBalance) {
      final rate = quote.lowBalance!.baseAmount / quote.lowBalance!.quoteAmount;
      _sideswapService.stopQuotes();
      return rate;
    }

    final rate = quote.quote!.baseAmount / quote.quote!.quoteAmount;
    _sideswapService.stopQuotes();
    return rate;
  }

  @override
  Future<SwapOperation> startNewSwapOperation(
    Asset sendAsset,
    Asset receiveAsset,
    BigInt sendAmount,
  ) async {
    final market = await _getMarket(sendAsset, receiveAsset);
    final utxos = await _liquidWallet.getUtxos(sendAsset, sendAmount);

    final (recvAddress, changeAddress) = await _getAddresses();

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

    final quote = await _sideswapService.quoteResponseStream.single;
    if (quote.isError) {
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
  }

  Future<String> confirmSwapOperation(SwapOperation operation) async {
    final swapPset = await _sideswapService.getQuoteDetails(operation.id);
    if (swapPset == null) {
      throw Exception("Failed to get swap pset.");
    }

    final signedPset = await _liquidWallet.signPset(swapPset);

    final txid = await _sideswapService.signQuote(operation.id, signedPset);
    if (txid == null) {
      throw Exception("Failed to submit swap.");
    }

    return txid;
  }

  Future<(String, String)> _getAddresses() async {
    final futures = <Future<String>>[
      _liquidWallet.getAddress(),
      _liquidWallet.getAddress(),
    ];
    final (recvAddress, changeAddress) =
        await Future.wait<String>(futures) as (String, String);

    return (recvAddress, changeAddress);
  }

  Future<SideswapMarket> _getMarket(Asset sendAsset, Asset receiveAsset) async {
    final markets = await _sideswapService.getMarkets();
    final market = markets.firstWhere(
      (m) =>
          m.baseAssetId == Asset.toId(sendAsset) &&
              m.quoteAssetId == Asset.toId(receiveAsset) ||
          m.baseAssetId == Asset.toId(receiveAsset) &&
              m.quoteAssetId == Asset.toId(sendAsset),
    );

    return market;
  }
}
