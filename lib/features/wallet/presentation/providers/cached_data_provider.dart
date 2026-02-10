import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
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

  Future<void> fetchAssetPriceHistory(Asset asset) async {
    if (!mounted) return;

    if (state.priceHistory.containsKey(asset) &&
        state.lastUpdated != null &&
        DateTime.now().difference(state.lastUpdated!).inMinutes < 5) {
      return;
    }

    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await ref.read(assetPriceHistoryProvider(asset).future);

      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );
      updatedPriceHistory[asset] = result;

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
      updatedPriceHistory[asset] = Left('Erro ao carregar dados: $e');

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
      updatedPriceHistory[asset] = result;

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
      updatedPriceHistory[asset] = Left('Erro ao carregar dados: $e');

      state = state.copyWith(
        priceHistory: updatedPriceHistory,
        isLoading: false,
      );
    }
  }

  Future<void> fetchMultipleAssets(List<Asset> assets) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final futures = assets.map(
        (asset) => ref.read(assetPriceHistoryProvider(asset).future),
      );

      final results = await Future.wait(futures);

      if (!mounted) return;

      final updatedPriceHistory = Map<Asset, Either<String, List<double>>>.from(
        state.priceHistory,
      );

      for (int i = 0; i < assets.length; i++) {
        updatedPriceHistory[assets[i]] = results[i];
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
    state = state.copyWith(priceHistory: {}, lastUpdated: null);

    await fetchMultipleAssets(assets);
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

  Future<void> fetchTransactions() async {
    final logger = ref.read(appLoggerProvider);

    if (!mounted) {
      logger.warning(
        'TransactionHistoryNotifier',
        'Not mounted, skipping fetch',
      );
      return;
    }

    // Check if we have valid cached data
    if (state.transactions != null &&
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
      'Manual refresh requested, clearing cache',
    );
    state = state.copyWith(clearTransactions: true, clearLastUpdated: true);

    await fetchTransactions();
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

  Future<void> fetchBalance(Asset asset) async {
    if (!mounted) return;

    if (state.balances.containsKey(asset) &&
        state.lastUpdated != null &&
        DateTime.now().difference(state.lastUpdated!).inMinutes < 1) {
      return;
    }

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

  Future<void> fetchMultipleBalances(List<Asset> assets) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final futures = assets.map(
        (asset) => ref.read(balanceProvider(asset).future),
      );

      final results = await Future.wait(futures);

      if (!mounted) return;
      final updatedBalances = Map<Asset, Either<WalletError, BigInt>>.from(
        state.balances,
      );

      for (int i = 0; i < assets.length; i++) {
        updatedBalances[assets[i]] = results[i];
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
    state = state.copyWith(balances: {}, lastUpdated: null);
    await fetchMultipleBalances(assets);
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
      return AssetPriceHistoryNotifier(ref);
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
