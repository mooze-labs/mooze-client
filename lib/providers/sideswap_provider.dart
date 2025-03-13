// lib/providers/sideswap/sideswap_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/repositories/sideswap.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:lwk/lwk.dart';
import 'dart:math' as math;

part 'sideswap_provider.g.dart';

// Repository provider
@Riverpod(keepAlive: true)
SideswapRepository sideswapRepository(Ref ref) {
  final repository = SideswapRepository(isTestnet: false);

  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
}

// Available markets provider
@riverpod
class SideswapMarkets extends _$SideswapMarkets {
  @override
  Future<List<SideswapMarket>> build() async {
    final repository = ref.watch(sideswapRepositoryProvider);
    final markets = await repository.listMarkets();

    return markets.map((market) => SideswapMarket.fromJson(market)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sideswapRepositoryProvider);
      final markets = await repository.listMarkets();
      return markets.map((market) => SideswapMarket.fromJson(market)).toList();
    });
  }
}

// Class to hold active quote information
class QuoteInfo {
  final int quoteSubId;
  final String feeAsset;
  StreamSubscription? subscription;
  Map<String, dynamic>? latestQuote;

  QuoteInfo({
    required this.quoteSubId,
    required this.feeAsset,
    this.subscription,
    this.latestQuote,
  });
}

// Active quote provider
@riverpod
class SideswapActiveQuote extends _$SideswapActiveQuote {
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  QuoteInfo? build() {
    ref.onDispose(() {
      _notificationSubscription?.cancel();
      state?.subscription?.cancel();
    });

    return null;
  }

  Future<void> startQuote({
    required String baseAssetId,
    required String quoteAssetId,
    required String assetType, // "Base" or "Quote"
    required int amount,
    required String tradeDir, // "Buy" or "Sell"
    required String receiveAddress,
    required String changeAddress,
  }) async {
    // Cancel previous subscriptions
    _notificationSubscription?.cancel();
    state?.subscription?.cancel();

    // Get repository
    final repository = ref.read(sideswapRepositoryProvider);

    // Get UTXOs from Liquid wallet
    final liquidWallet = ref.read(liquidWalletNotifierProvider.notifier);
    final utxos = await liquidWallet.fetchUtxos();

    // Format UTXOs for Sideswap
    final formattedUtxos = repository.formatUtxos(utxos);

    // Start quotes
    final result = await repository.startQuotes(
      baseAssetId: baseAssetId,
      quoteAssetId: quoteAssetId,
      assetType: assetType,
      amount: amount,
      tradeDir: tradeDir,
      utxos: formattedUtxos,
      receiveAddress: receiveAddress,
      changeAddress: changeAddress,
    );

    // Create quote info
    final quoteInfo = QuoteInfo(
      quoteSubId: result['quote_sub_id'],
      feeAsset: result['fee_asset'],
    );

    // Subscribe to notifications
    _notificationSubscription = repository.notifications.listen((notification) {
      if (notification['method'] == 'market' &&
          notification['params'].containsKey('quote')) {
        final quote = notification['params']['quote'];

        // Check if this notification is for our quote
        if (quote['quote_sub_id'] == quoteInfo.quoteSubId) {
          state = QuoteInfo(
            quoteSubId: quoteInfo.quoteSubId,
            feeAsset: quoteInfo.feeAsset,
            subscription: _notificationSubscription,
            latestQuote: quote,
          );
        }
      }
    });

    state = quoteInfo;
  }

  Future<String?> acceptQuote(int quoteId) async {
    if (state == null || state?.latestQuote == null) {
      throw Exception('No active quote to accept');
    }

    // Check if quote has a successful status
    final quote = state!.latestQuote!;
    if (!quote['status'].containsKey('Success')) {
      throw Exception('Cannot accept quote: ${quote['status']}');
    }

    final repository = ref.read(sideswapRepositoryProvider);

    // Get the quote PSET
    final psetResult = await repository.getQuote(quoteId);
    final psetBase64 = psetResult['pset'];

    // Sign the PSET using the liquid wallet
    // This would need to be implemented based on your wallet capabilities
    // For now, returning null as a placeholder

    // final signedPset = /* Sign the PSET using your wallet */;
    // return await repository.takerSign(quoteId, signedPset);

    return null;
  }
}

// Swap screen state provider
@riverpod
class SwapScreenNotifier extends _$SwapScreenNotifier {
  @override
  SwapState build() {
    return SwapState();
  }

  void setFromAsset(Asset asset) {
    state = state.copyWith(fromAsset: asset);
  }

  void setToAsset(Asset asset) {
    state = state.copyWith(toAsset: asset);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setDirection(SwapDirection direction) {
    state = state.copyWith(direction: direction);
  }

  Future<void> requestQuote() async {
    if (state.fromAsset == null ||
        state.toAsset == null ||
        state.amount == null) {
      throw Exception('Missing asset or amount information');
    }

    // Convert to satoshis
    final int amountSats =
        (state.amount! * math.pow(10, state.fromAsset!.precision)).toInt();

    // Get addresses
    final liquidWallet = ref.read(liquidWalletNotifierProvider.notifier);
    final receiveAddress = await liquidWallet.generateAddress();
    final changeAddress = await liquidWallet.generateAddress();

    if (receiveAddress == null || changeAddress == null) {
      throw Exception('Failed to generate addresses');
    }

    // Determine asset types and direction
    String assetType, tradeDir;

    // Get available markets to find base/quote configuration
    final marketsAsync = ref.read(sideswapMarketsProvider);
    final markets = await marketsAsync.when(
      data: (data) => data,
      loading: () => throw Exception('Markets still loading'),
      error:
          (error, stackTrace) =>
              throw Exception('Error loading markets: $error'),
    );

    // Find the market that matches our assets
    SideswapMarket? market;
    for (final m in markets) {
      if ((m.baseAssetId == state.fromAsset!.liquidAssetId &&
              m.quoteAssetId == state.toAsset!.liquidAssetId) ||
          (m.baseAssetId == state.toAsset!.liquidAssetId &&
              m.quoteAssetId == state.fromAsset!.liquidAssetId)) {
        market = m;
        break;
      }
    }

    if (market == null) {
      throw Exception('No market found for these assets');
    }

    // Configure the request based on the market and direction
    if (state.direction == SwapDirection.sell) {
      if (state.fromAsset!.liquidAssetId == market.baseAssetId) {
        assetType = 'Base';
        tradeDir = 'Sell';
      } else {
        assetType = 'Quote';
        tradeDir = 'Sell';
      }
    } else {
      // Buy
      if (state.toAsset!.liquidAssetId == market.baseAssetId) {
        assetType = 'Base';
        tradeDir = 'Buy';
      } else {
        assetType = 'Quote';
        tradeDir = 'Buy';
      }
    }

    // Request quote
    final quoteProvider = ref.read(sideswapActiveQuoteProvider.notifier);
    await quoteProvider.startQuote(
      baseAssetId: market.baseAssetId,
      quoteAssetId: market.quoteAssetId,
      assetType: assetType,
      amount: amountSats,
      tradeDir: tradeDir,
      receiveAddress: receiveAddress,
      changeAddress: changeAddress,
    );
  }

  Future<String?> acceptQuote() async {
    final quoteProvider = ref.read(sideswapActiveQuoteProvider);
    if (quoteProvider == null || quoteProvider.latestQuote == null) {
      throw Exception('No quote to accept');
    }

    final quoteJson = quoteProvider.latestQuote!;
    if (!quoteJson['status'].containsKey('Success')) {
      throw Exception('No valid quote to accept');
    }

    final success = quoteJson['status']['Success'];
    final quoteId = success['quote_id'];

    state = state.copyWith(isSubmitting: true);

    try {
      final quoteNotifier = ref.read(sideswapActiveQuoteProvider.notifier);
      final txid = await quoteNotifier.acceptQuote(quoteId);

      state = state.copyWith(isSubmitting: false);

      return txid;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}
