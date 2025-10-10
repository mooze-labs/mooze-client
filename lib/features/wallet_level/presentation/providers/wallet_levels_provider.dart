import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/wallet_level_entity.dart';
import '../../domain/entities/current_user_wallet_entity.dart';
import '../../domain/repositories/wallet_levels_repository.dart';
import '../../data/repositories/wallet_levels_repository_impl.dart';
import '../../data/datasources/wallet_levels_remote_data_source.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final walletLevelsDataSourceProvider = Provider<WalletLevelsRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return WalletLevelsRemoteDataSource(dio: dio);
});

final walletLevelsRepositoryProvider = Provider<WalletLevelsRepository>((ref) {
  final dataSource = ref.watch(walletLevelsDataSourceProvider);
  return WalletLevelsRepositoryImpl(dataSource: dataSource);
});

final walletLevelsProvider = FutureProvider<List<WalletLevelEntity>>((
  ref,
) async {
  final repository = ref.watch(walletLevelsRepositoryProvider);
  return repository.getAllWalletLevels();
});

final walletLevelByTypeProvider =
    FutureProvider.family<WalletLevelEntity, WalletLevelType>((
      ref,
      type,
    ) async {
      final repository = ref.watch(walletLevelsRepositoryProvider);
      return repository.getWalletLevelByType(type);
    });

final currentUserWalletProvider = FutureProvider<CurrentUserWalletEntity>((
  ref,
) async {
  // TODO: GET FROM API USER
  await Future.delayed(const Duration(milliseconds: 500));
  return const CurrentUserWalletEntity(
    currentLimit: 500.0,
    maximumPossibleLimit: 3000.0,
    minimumLimit: 20.0,
    currentLevel: 'Prata',
  );
});
