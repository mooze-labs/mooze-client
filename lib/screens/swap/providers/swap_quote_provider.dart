import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/wallet/liquid.dart';
import 'package:mooze_mobile/screens/swap/models/swap_input_model.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_asset_type_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_base_asset_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_market_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_asset_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

part 'swap_quote_provider.g.dart';

class SwapQuoteState {
  final SideswapQuote? quote;
  final String assetType;
  final SwapDirection direction;

  SwapQuoteState({
    required this.quote,
    required this.assetType,
    required this.direction,
  });
}

@riverpod
class SwapQuoteNotifier extends _$SwapQuoteNotifier {
  StreamSubscription<QuoteResponse>? _quoteSubscription;
  SideswapQuote? quote;
  String assetType = "Base";

  @override
  SwapQuoteState? build() {
    ref.onDispose(() {
      _quoteSubscription?.cancel();
    });
    return null;
  }

  Future<List<SwapUtxo>?> _fetchUtxos(String assetId, int amount) async {
    int sumAmount = 0;
    final List<SwapUtxo> selectedUtxos = [];

    final liquidWallet =
        ref.read(liquidWalletRepositoryProvider) as LiquidWalletRepository;
    final utxos = await liquidWallet.fetchUtxos();
    final assetUtxos =
        utxos
            .where((utxo) => utxo.unblinded.asset == assetId)
            .map(
              (utxo) => SwapUtxo(
                txid: utxo.outpoint.txid,
                vout: utxo.outpoint.vout,
                value: utxo.unblinded.value.toInt(),
                valueBf: utxo.unblinded.valueBf,
                asset: utxo.unblinded.asset,
                assetBf: utxo.unblinded.assetBf,
              ),
            )
            .toList();

    if (assetUtxos.map((utxo) => utxo.value).fold(0, (a, b) => a + b) <
        amount) {
      return null;
    }

    for (final utxo in assetUtxos) {
      sumAmount += utxo.value;
      selectedUtxos.add(utxo);
      if (sumAmount >= amount) break;
    }

    return selectedUtxos;
  }

  Future<void> requestNewQuote(
    String sendAssetId,
    int sendAssetAmount,
    String recvAssetId,
  ) async {
    // Cancel any existing subscription
    _quoteSubscription?.cancel();
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.quoteResponseStream.drain();

    final sendLiquidId = AssetCatalog.getById(sendAssetId);
    final recvLiquidId = AssetCatalog.getById(recvAssetId);

    if (sendLiquidId == null || recvLiquidId == null) {
      if (kDebugMode) {
        print("No liquid asset found for $sendAssetId and $recvAssetId");
      }
      return;
    }

    if (sendLiquidId == recvLiquidId) {
      if (kDebugMode) {
        print("Same asset for $sendAssetId and $recvAssetId");
      }
      return;
    }

    final markets = await ref.read(sideswapRepositoryProvider).getMarkets();
    final market = markets.firstWhere(
      (market) =>
          (market.baseAssetId == sendLiquidId.liquidAssetId &&
              market.quoteAssetId == recvLiquidId.liquidAssetId) ||
          (market.baseAssetId == recvLiquidId.liquidAssetId &&
              market.quoteAssetId == sendLiquidId.liquidAssetId),
    );

    if (kDebugMode) {
      print("Market: $market");
    }

    if (market == null) {
      if (kDebugMode) {
        print("No market found for $sendAssetId and $recvAssetId");
      }
      return;
    }

    final liquidWallet = ref.read(liquidWalletRepositoryProvider);
    final receiveAddress = await liquidWallet.generateAddress();
    final changeAddress = await liquidWallet.generateAddress();

    final utxos = await _fetchUtxos(
      sendLiquidId.liquidAssetId!,
      sendAssetAmount,
    );

    if (utxos == null) {
      if (kDebugMode) {
        print("No utxos found for $sendAssetId and $recvAssetId");
      }
      return;
    }

    // Start listening to quote responses
    _quoteSubscription = sideswap.quoteResponseStream.listen((response) {
      if (kDebugMode) {
        print("Quote response received: ${response.isSuccess}");
        print("Current state before update: $state");
      }
      if (response.isSuccess) {
        if (kDebugMode) {
          print("Quote id: ${response.quote?.quoteId}");
          print("Base amount: ${response.quote?.baseAmount}");
          print("Quote asset amount: ${response.quote?.quoteAmount}");
          print("Server fee: ${response.quote?.serverFee}");
          print("Ttl: ${response.quote?.ttl}");
          print("Asset type: ${this.assetType}");
        }

        state = SwapQuoteState(
          quote: response.quote,
          assetType: this.assetType,
          direction: SwapDirection.sell,
        );

        this.quote = response.quote;

        if (kDebugMode) {
          print("State after update: $state");
          print("State quote: ${state?.quote}");
          print("State assetType: ${state?.assetType}");
          print("State direction: ${state?.direction}");
        }
      } else if (response.isError) {
        if (kDebugMode) {
          print("Quote error received: ${response.error?.errorMessage}");
        }
        state = null;
      } else if (response.isLowBalance) {
        if (kDebugMode) {
          print("Low balance received: ${response.lowBalance?.available}");
        }
        state = null;
      }
    });

    if (kDebugMode) {
      print("Starting quote request");
      print("Send asset: $sendAssetId");
      print("Send asset amount: $sendAssetAmount");
      print("Recv asset: $recvAssetId");
    }

    this.assetType =
        (sendLiquidId.liquidAssetId == market.quoteAssetId) ? "Quote" : "Base";
    ref
        .read(swapAssetTypeNotifierProvider.notifier)
        .updateAssetType(this.assetType);

    ref
        .read(swapBaseAssetNotifierProvider.notifier)
        .updateBaseAsset(market.baseAssetId);
    ref
        .read(swapQuoteAssetNotifierProvider.notifier)
        .updateQuoteAsset(market.quoteAssetId);

    // Start the quote request
    sideswap.startQuote(
      baseAsset: market.baseAssetId,
      quoteAsset: market.quoteAssetId,
      assetType: this.assetType,
      amount: sendAssetAmount,
      direction: SwapDirection.sell,
      utxos: utxos,
      receiveAddress: receiveAddress,
      changeAddress: changeAddress,
    );
  }

  void stopQuote() {
    _quoteSubscription?.cancel();
    ref.read(sideswapRepositoryProvider).stopQuotes();
    state = null;
  }
}
