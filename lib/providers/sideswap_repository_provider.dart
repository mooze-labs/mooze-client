import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/repositories/wallet/signer.dart';
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

  Future<String> _signPset(String pset) async {
    final signer =
        ref.read(liquidSignerRepositoryProvider) as LiquidSignerRepository;
    final signedPset = await signer.signPsetWithExtraDetails(pset);

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
Stream<int> pegInWalletBalance(Ref ref) {
  final repository = ref.watch(sideswapRepositoryProvider);

  // Subscribe to wallet balance updates
  repository.subscribeToPegInWalletBalance();

  return repository.pegInWalletBalanceStream;
}

@riverpod
Stream<int> pegOutWalletBalance(Ref ref) {
  final repository = ref.watch(sideswapRepositoryProvider);

  // Subscribe to wallet balance updates
  repository.subscribeToPegInWalletBalance();

  return repository.pegOutWalletBalanceStream;
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
