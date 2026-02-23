import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';

final initialDataLoaderProvider = FutureProvider<Either<String, bool>>((
  ref,
) async {
  try {
    final favoriteAssets = ref.read(favoriteAssetsProvider);
    final allAssets = ref.read(allAssetsProvider);

    final assetCacheNotifier = ref.read(
      assetPriceHistoryCacheProvider.notifier,
    );
    final transactionCacheNotifier = ref.read(
      transactionHistoryCacheProvider.notifier,
    );

    final futures = <Future<void>>[];

    for (final asset in favoriteAssets) {
      futures.add(assetCacheNotifier.fetchAssetPriceHistoryInitial(asset));
    }

    for (final asset in allAssets) {
      futures.add(ref.read(balanceProvider(asset).future).then((_) {}));
    }

    futures.add(transactionCacheNotifier.fetchTransactionsInitial());

    await Future.wait(futures);

    return const Right(true);
  } catch (e) {
    return Left('Erro ao carregar dados iniciais: $e');
  }
});

final isInitialDataLoadedProvider = Provider<bool>((ref) {
  final dataLoader = ref.watch(initialDataLoaderProvider);
  return dataLoader.when(
    data: (result) => result.fold((error) => false, (success) => success),
    loading: () => false,
    error: (_, _) => false,
  );
});
