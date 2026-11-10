import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';

import 'fiat_price_provider.dart';
import 'transaction_provider.dart';
import 'balance_provider.dart';

class AssetPriceHistoryState {
  final Map<Asset, Either<String, List<double>>> priceHistory;
  final bool isLoading;
  final DateTime? lastUpdated;

  const AssetPriceHistoryState({
    this.priceHistory = const {},
    this.isLoading = false,
    this.lastUpdated,
  });

  AssetPriceHistoryState copyWith({
    Map<Asset, Either<String, List<double>>>? priceHistory,
    bool? isLoading,
    DateTime? lastUpdated,
  }) {
    return AssetPriceHistoryState(
      priceHistory: priceHistory ?? this.priceHistory,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class BalanceState {
  final Map<Asset, Either<WalletError, BigInt>> balances;
  final bool isLoading;
  final DateTime? lastUpdated;

  const BalanceState({
    this.balances = const {},
    this.isLoading = false,
    this.lastUpdated,
  });

  BalanceState copyWith({
    Map<Asset, Either<WalletError, BigInt>>? balances,
    bool? isLoading,
    DateTime? lastUpdated,
  }) {
    return BalanceState(
      balances: balances ?? this.balances,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TransactionHistoryState {
  final Either<WalletError, List<Transaction>>? transactions;
  final bool isLoading;
  final DateTime? lastUpdated;

  const TransactionHistoryState({
    this.transactions,
    this.isLoading = false,
    this.lastUpdated,
  });

  TransactionHistoryState copyWith({
    Either<WalletError, List<Transaction>>? transactions,
    bool? isLoading,
    DateTime? lastUpdated,
    bool clearTransactions = false,
    bool clearLastUpdated = false,
  }) {
    return TransactionHistoryState(
      transactions:
          clearTransactions ? null : (transactions ?? this.transactions),
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: clearLastUpdated ? null : (lastUpdated ?? this.lastUpdated),
    );
  }
}

class AssetPriceHistoryNotifier extends StateNotifier<AssetPriceHistoryState> {
  final Ref ref;

  AssetPriceHistoryNotifier(this.ref) : super(const AssetPriceHistoryState());

  /// Puts [result] in [histories]. A failure never replaces a history that
  /// loaded before, so a refresh while offline keeps the sparkline.
  static void _put(
    Map<Asset, Either<String, List<double>>> histories,
    Asset asset,
    Either<String, List<double>> result,
  ) {
    if (result.isLeft() && (histories[asset]?.isRight() ?? false)) return;
    histories[asset] = result;
  }

  /// Loads again the histories that failed, for example offline. Nothing
  /// else asks for them: a row asks only for a history it has not got.
  Future<void> retryFailed() async {
    final failed = [
      for (final MapEntry(key: asset, value: history)
          in state.priceHistory.entries)
        if (history.isLeft()) asset,
    ];
    if (failed.isEmpty) return;
    await fetchMultipleAssets(failed, forceRefresh: true);
  }

  Future<void> fetchAssetPriceHistory(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    if (!forceRefresh &&
        state.priceHistory.containsKey(asset) &&
        state.lastUpdated != null &&
        DateTime.now().difference(state.lastUpdated!).inMinutes < 5) {
      return;
    }

    if (!mounted) return;

    state = state.copyWith(isLoading: true);

    try {
      // A forced refresh reloads the history once (see fetchMultipleAssets).
      final result = await (forceRefresh
          ? ref.refresh(assetPriceHistoryProvider(asset).future)
          : ref.read(assetPriceHistoryProvider(asset).future));

      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );
      _put(updatedPriceHistory, asset, result);

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );
      _put(updatedPriceHistory, asset, Left('Erro ao carregar dados: $e'));

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
      );
    }
  }

  Future<void> fetchAssetPriceHistoryInitial(Asset asset) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(assetPriceHistoryProvider(asset).future);

      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );
      _put(updatedPriceHistory, asset, result);

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );
      _put(updatedPriceHistory, asset, Left('Erro ao carregar dados: $e'));

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
      );
    }
  }

  Future<void> fetchMultipleAssets(
    List<Asset> assets, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    // If forceRefresh, fetch all assets. Otherwise filter cached ones.
    final assetsToFetch =
        forceRefresh
            ? assets
            : assets.where((asset) {
              return !state.priceHistory.containsKey(asset) ||
                  state.lastUpdated == null ||
                  DateTime.now().difference(state.lastUpdated!).inMinutes >= 5;
            }).toList();

    if (assetsToFetch.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      // A forced refresh reloads each history once. An invalidate followed
      // by a read would rebuild a live provider twice: two requests.
      final futures = assetsToFetch.map(
        (asset) => forceRefresh
            ? ref.refresh(assetPriceHistoryProvider(asset).future)
            : ref.read(assetPriceHistoryProvider(asset).future),
      );

      final results = await Future.wait(futures);

      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );

      for (int i = 0; i < assetsToFetch.length; i++) {
        _put(updatedPriceHistory, assetsToFetch[i], results[i]);
      }

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh(List<Asset> assets) async {
    if (!mounted) return;
    await fetchMultipleAssets(assets, forceRefresh: true);
  }

  Either<String, List<double>>? getAssetData(Asset asset) {
    return state.priceHistory[asset];
  }

  void reset() {
    if (!mounted) return;
    state = const AssetPriceHistoryState();
  }
}

class TransactionHistoryNotifier
    extends StateNotifier<TransactionHistoryState> {
  final Ref ref;

  TransactionHistoryNotifier(this.ref)
    : super(const TransactionHistoryState()) {
    final logger = ref.read(appLoggerProvider);
    logger.info(
      'TransactionHistoryNotifier',
      'Instance created - Will fetch on demand',
    );
  }

  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    final logger = ref.read(appLoggerProvider);

    if (!mounted) {
      logger.warning(
        'TransactionHistoryNotifier',
        'Not mounted, skipping fetch',
      );
      return;
    }

    // Check if we have valid cached data (skip check if forceRefresh is true)
    if (!forceRefresh &&
        state.transactions != null &&
        state.lastUpdated != null &&
        DateTime.now().difference(state.lastUpdated!).inMinutes < 2) {
      logger.info(
        'TransactionHistoryNotifier',
        'Using cached transactions (age: ${DateTime.now().difference(state.lastUpdated!).inSeconds}s)',
      );
      return;
    }

    if (!mounted) return;

    logger.info(
      'TransactionHistoryNotifier',
      'Fetching transactions from repository (cache expired or empty)...',
    );

    // CRITICAL: Invalidate the FutureProvider to force fresh data fetch
    if (forceRefresh) {
      logger.debug(
        'TransactionHistoryNotifier',
        '🔄 Force refresh - invalidating transactionHistoryProvider',
      );
      ref.invalidate(transactionHistoryProvider);
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(transactionHistoryProvider.future);

      if (!mounted) return;

      result.fold(
        (error) {
          logger.error(
            'TransactionHistoryNotifier',
            'Failed to fetch transactions',
            error: error,
          );
        },
        (transactions) {
          logger.info(
            'TransactionHistoryNotifier',
            'Loaded ${transactions.length} transactions, caching for 2 minutes',
          );
        },
      );

      state = state.copyWith(
        transactions: result,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;

      logger.critical(
        'TransactionHistoryNotifier',
        'Exception while fetching transactions',
        error: e,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        transactions: Left(
          WalletError(
            WalletErrorType.networkError,
            'Erro ao carregar transações: $e',
          ),
        ),
        isLoading: false,
      );
    }
  }

  Future<void> fetchTransactionsInitial() async {
    final logger = ref.read(appLoggerProvider);

    if (!mounted) {
      logger.warning(
        'TransactionHistoryNotifier',
        'Not mounted, skipping initial fetch',
      );
      return;
    }

    logger.info(
      'TransactionHistoryNotifier',
      'Initial fetch - Loading transactions...',
    );
    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(transactionHistoryProvider.future);

      if (!mounted) return;

      result.fold(
        (error) {
          logger.error(
            'TransactionHistoryNotifier',
            'Initial fetch failed',
            error: error,
          );
        },
        (transactions) {
          logger.info(
            'TransactionHistoryNotifier',
            'Initial load: ${transactions.length} transactions cached',
          );
        },
      );

      state = state.copyWith(
        transactions: result,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;

      logger.critical(
        'TransactionHistoryNotifier',
        'Exception during initial fetch',
        error: e,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        transactions: Left(
          WalletError(
            WalletErrorType.networkError,
            'Erro ao carregar transações: $e',
          ),
        ),
        isLoading: false,
      );
    }
  }

  Future<void> refresh() async {
    final logger = ref.read(appLoggerProvider);

    if (!mounted) return;

    logger.info(
      'TransactionHistoryNotifier',
      'Manual refresh requested, forcing fresh data fetch',
    );

    await fetchTransactions(forceRefresh: true);
  }

  void reset() {
    final logger = ref.read(appLoggerProvider);

    if (!mounted) return;

    logger.info(
      'TransactionHistoryNotifier',
      'Resetting cache to initial state',
    );
    state = const TransactionHistoryState();
  }
}

class BalanceNotifier extends StateNotifier<BalanceState> {
  final Ref ref;

  BalanceNotifier(this.ref) : super(const BalanceState());

  Future<void> fetchBalance(Asset asset, {bool forceRefresh = false}) async {
    if (!mounted) return;

    if (!forceRefresh &&
        state.balances.containsKey(asset) &&
        state.lastUpdated != null &&
        DateTime.now().difference(state.lastUpdated!).inMinutes < 1) {
      return;
    }

    if (!mounted) return;

    // CRITICAL: Invalidate the FutureProvider to force fresh data fetch
    if (forceRefresh) {
      ref.invalidate(balanceProvider(asset));
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(balanceProvider(asset).future);

      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );
      updatedBalances[asset] = result;

      state = state.copyWith(
        balances: updatedBalances,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );
      updatedBalances[asset] = Left(
        WalletError(WalletErrorType.networkError, 'Erro ao carregar saldo: $e'),
      );

      state = state.copyWith(balances: updatedBalances, isLoading: false);
    }
  }

  Future<void> fetchBalanceInitial(Asset asset) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(balanceProvider(asset).future);

      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );
      updatedBalances[asset] = result;

      state = state.copyWith(
        balances: updatedBalances,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );
      updatedBalances[asset] = Left(
        WalletError(WalletErrorType.networkError, 'Erro ao carregar saldo: $e'),
      );

      state = state.copyWith(balances: updatedBalances, isLoading: false);
    }
  }

  Future<void> fetchMultipleBalances(
    List<Asset> assets, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    // If forceRefresh, fetch all assets. Otherwise filter cached ones.
    final assetsToFetch =
        forceRefresh
            ? assets
            : assets.where((asset) {
              return !state.balances.containsKey(asset) ||
                  state.lastUpdated == null ||
                  DateTime.now().difference(state.lastUpdated!).inMinutes >= 1;
            }).toList();

    if (assetsToFetch.isEmpty) return;

    // CRITICAL: Invalidate FutureProviders to force fresh data fetch
    if (forceRefresh) {
      for (final asset in assetsToFetch) {
        ref.invalidate(balanceProvider(asset));
      }
    }

    state = state.copyWith(isLoading: true);

    try {
      final futures = assetsToFetch.map(
        (asset) => ref.read(balanceProvider(asset).future),
      );

      final results = await Future.wait(futures);

      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );

      for (int i = 0; i < assetsToFetch.length; i++) {
        updatedBalances[assetsToFetch[i]] = results[i];
      }

      state = state.copyWith(
        balances: updatedBalances,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh(List<Asset> assets) async {
    if (!mounted) return;
    await fetchMultipleBalances(assets, forceRefresh: true);
  }

  Either<WalletError, BigInt>? getAssetBalance(Asset asset) {
    return state.balances[asset];
  }

  void reset() {
    if (!mounted) return;
    state = const BalanceState();
  }
}

final assetPriceHistoryCacheProvider =
    StateNotifierProvider<AssetPriceHistoryNotifier, AssetPriceHistoryState>((
      ref,
    ) {
      final notifier = AssetPriceHistoryNotifier(ref);
      // The histories that failed offline load again when the network
      // returns, without a restart of the app.
      ref.listen<bool>(isOnlineProvider, (wasOnline, online) {
        if (wasOnline == false && online) notifier.retryFailed();
      });
      return notifier;
    });

final balanceCacheProvider =
    StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {
      return BalanceNotifier(ref);
    });

final transactionHistoryCacheProvider =
    StateNotifierProvider<TransactionHistoryNotifier, TransactionHistoryState>((
      ref,
    ) {
      return TransactionHistoryNotifier(ref);
    });

final cachedAssetPriceHistoryProvider =
    Provider.family<Either<String, List<double>>?, Asset>((ref, asset) {
      final state = ref.watch(assetPriceHistoryCacheProvider);
      return state.priceHistory[asset];
    });

final cachedBalanceProvider =
    Provider.family<Either<WalletError, BigInt>?, Asset>((ref, asset) {
      final state = ref.watch(balanceCacheProvider);
      return state.balances[asset];
    });

final cachedTransactionHistoryProvider =
    Provider<Either<WalletError, List<Transaction>>?>((ref) {
      final state = ref.watch(transactionHistoryCacheProvider);
      return state.transactions;
    });

final isLoadingDataProvider = Provider<bool>((ref) {
  final assetState = ref.watch(assetPriceHistoryCacheProvider);
  final transactionState = ref.watch(transactionHistoryCacheProvider);
  final balanceState = ref.watch(balanceCacheProvider);

  return assetState.isLoading ||
      transactionState.isLoading ||
      balanceState.isLoading;
});
