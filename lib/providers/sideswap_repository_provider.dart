import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/repositories/sideswap.dart';
import 'package:mooze_mobile/models/sideswap.dart';

part 'sideswap_repository_provider.g.dart';

/// Provider for the SideswapRepository
@Riverpod(keepAlive: true)
SideswapRepository sideswapRepository(Ref ref) {
  final repository = SideswapRepository();

  // Initialize the repository
  repository.init();

  // Clean up on dispose
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
}

/// Provider for server status
@riverpod
Stream<ServerStatus> serverStatus(Ref ref) {
  final repository = ref.watch(sideswapRepositoryProvider);

  // Request a refresh of server status
  repository.getServerStatus();

  return repository.serverStatusStream;
}

/// Provider for available assets
@riverpod
Future<List<SideswapAsset>> sideswapAssets(Ref ref) async {
  final repository = ref.watch(sideswapRepositoryProvider);
  return repository.getAssets();
}

/// Provider for available markets
@riverpod
Future<List<SideswapMarket>> sideswapMarkets(Ref ref) async {
  final repository = ref.watch(sideswapRepositoryProvider);
  return repository.getMarkets();
}

/// Provider for quote responses
@riverpod
Stream<QuoteResponse> quoteResponses(Ref ref) {
  final repository = ref.watch(sideswapRepositoryProvider);
  return repository.quoteResponseStream;
}

/// Notifier for swap operations
@riverpod
class SwapNotifier extends _$SwapNotifier {
  @override
  SwapState build() {
    return SwapState();
  }

  /// Update the swap direction
  void setDirection(SwapDirection direction) {
    state = state.copyWith(direction: direction);
  }

  /// Set the assets for the swap
  void setAssets({Asset? fromAsset, Asset? toAsset}) {
    state = state.copyWith(fromAsset: fromAsset, toAsset: toAsset);
  }

  /// Set the amount for the swap
  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  /// Start the swap quote process
  /*
  Future<void> requestQuote({
    required SideswapMarket market,
    required List<SwapUtxo> utxos,
  }) async {
    // Validate state
    if (state.fromAsset == null ||
        state.toAsset == null ||
        state.amount == null) {
      throw Exception("Swap parameters not fully specified");
    }

    state = state.copyWith(isSubmitting: true);

    final repository = ref.read(sideswapRepositoryProvider);
    final receiveAddress =
        await ref.read(liquidWalletNotifierProvider.notifier).generateAddress();
    final changeAddress =
        await ref.read(liquidWalletNotifierProvider.notifier).generateAddress();

    if (receiveAddress == null || changeAddress == null) {
      throw Exception("Failed to generate addresses");
    }

    // Determine which asset we're specifying the amount for
    final String assetType;
    final SwapDirection direction;
    final int amount;

    if (state.direction == SwapDirection.sell) {
      // User is selling fromAsset
      assetType =
          state.fromAsset!.liquidAssetId == market.baseAssetId
              ? "Base"
              : "Quote";
      direction = SwapDirection.sell;
      amount = (state.amount! * pow(10, state.fromAsset!.precision)).toInt();
    } else {
      // User is buying toAsset
      assetType =
          state.toAsset!.liquidAssetId == market.baseAssetId ? "Base" : "Quote";
      direction = SwapDirection.buy;
      amount = (state.amount! * pow(10, state.toAsset!.precision)).toInt();
    }

    try {
      // Start listening for quote responses
      final subscription = repository.quoteResponseStream.listen((
        quoteResponse,
      ) {
        if (quoteResponse.isSuccess) {
          state = state.copyWith(
            quote: quoteResponse.quote,
            isSubmitting: false,
          );
        } else if (quoteResponse.isError) {
          throw Exception("Quote error: ${quoteResponse.error!.errorMessage}");
        } else if (quoteResponse.isLowBalance) {
          throw Exception(
            "Low balance: only ${quoteResponse.lowBalance!.available} available",
          );
        }
      });

      // Make the request
      repository.startQuote(
        baseAsset: market.baseAssetId,
        quoteAsset: market.quoteAssetId,
        assetType: assetType,
        amount: amount,
        direction: direction,
        utxos: utxos,
        receiveAddress: receiveAddress,
        changeAddress: changeAddress,
      );

      // Wait for a response (or timeout)
      await Future.delayed(const Duration(seconds: 10));
      subscription.cancel();

      if (state.isSubmitting) {
        // If we're still submitting after the timeout, something went wrong
        state = state.copyWith(isSubmitting: false);
        throw Exception("Quote request timed out");
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
  */

  /// Execute the swap with the current quote
  Future<String?> executeSwap() async {
    if (state.quote == null) {
      throw Exception("No quote available");
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final repository = ref.read(sideswapRepositoryProvider);

      // Get the PSET
      final pset = await repository.getQuoteDetails(state.quote!.quoteId);
      if (pset == null) {
        throw Exception("Failed to get PSET");
      }

      final signedPset = await _signPset(pset);

      // Submit the signed transaction
      final txid = await repository.signQuote(state.quote!.quoteId, signedPset);

      state = state.copyWith(
        isSubmitting: false,
        quote: null, // Clear the quote after execution
      );

      return txid;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  // Placeholder for the PSET signing logic
  Future<String> _signPset(String pset) async {
    final signedPset = await ref
        .read(liquidWalletNotifierProvider.notifier)
        .signPsetWithExtraDetails(pset);

    return signedPset;
  }

  /// Reset the swap state
  void reset() {
    state = SwapState();
  }
}

/// Provider for peg operations
@riverpod
class PegNotifier extends _$PegNotifier {
  @override
  AsyncValue<PegOrderResponse?> build() {
    return const AsyncValue.data(null);
  }

  /// Start a peg-in operation
  Future<PegOrderResponse?> startPegIn(String receiveAddress) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sideswapRepositoryProvider);
      final response = await repository.startPegOperation(true, receiveAddress);
      state = AsyncValue.data(response);
      return response;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Start a peg-out operation
  Future<PegOrderResponse?> startPegOut(String receiveAddress) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sideswapRepositoryProvider);
      final response = await repository.startPegOperation(
        false,
        receiveAddress,
      );
      state = AsyncValue.data(response);
      return response;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}

/// Provider for peg status operations
@riverpod
class PegStatusNotifier extends _$PegStatusNotifier {
  @override
  AsyncValue<PegOrderStatus?> build() {
    return const AsyncValue.data(null);
  }

  /// Get status of a peg operation
  Future<PegOrderStatus?> checkStatus(bool isPegIn, String orderId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sideswapRepositoryProvider);
      final status = await repository.getPegStatus(isPegIn, orderId);
      state = AsyncValue.data(status);
      return status;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}

/// Provider for wallet balance
@riverpod
Stream<WalletBalance> walletBalance(Ref ref) {
  final repository = ref.watch(sideswapRepositoryProvider);

  // Subscribe to wallet balance updates
  repository.subscribeToWalletBalance();

  return repository.walletBalanceStream;
}

/// Provider for market data
/*
@riverpod
class MarketDataNotifer extends _$MarketDataNotifer {
  StreamSubscription? _subscription;

  @override;
  AsyncValue<List<AssetPairMarketData>> build() {
    // Clean up any existing subscription when rebuilding
    _subscription?.cancel();
    _subscription = null;

    return const AsyncValue.loading();
  }

  /// Subscribe to market data for a specific asset pair
  void subscribeToMarketData(String baseAsset, String quoteAsset) {
    _subscription?.cancel();

    final repository = ref.read(sideswapRepositoryProvider);

    state = const AsyncValue.loading();

    repository.subscribeToAssetPriceStream(baseAsset, quoteAsset);

    _subscription = repository.marketDataStream.listen(
      (data) {
        state = AsyncValue.data(data);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  /// Unsubscribe from market data
  void unsubscribeFromMarketData(String baseAsset, String quoteAsset) {
    if (_subscription != null) {
      _subscription?.cancel();
      _subscription = null;

      final repository = ref.read(sideswapRepositoryProvider);
      state = const AsyncValue.loading();

      repository.unsubscribeFromAssetPriceStream(baseAsset, quoteAsset);
      state = AsyncValue.data(data);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
*/
