import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet_level/domain/repositories/wallet_levels_repository.dart';
import 'package:mooze_mobile/features/wallet_level/domain/usecases/get_all_wallet_levels_usecase.dart';
import 'package:mooze_mobile/features/wallet_level/domain/usecases/get_wallet_level_by_type_usecase.dart';
import 'package:mooze_mobile/features/wallet_level/external/datasources/wallet_levels_remote_datasource.dart';
import 'package:mooze_mobile/features/wallet_level/infra/datasources/wallet_levels_datasource.dart';
import 'package:mooze_mobile/features/wallet_level/infra/repositories/wallet_levels_repository_impl.dart';

/// Wallet Levels Dependency Injection Container
/// Clean Architecture: External → Infra → Domain → Presentation

// Data Sources
final walletLevelsDataSourceProvider = Provider<WalletLevelsDataSource>((ref) {
  final dio = Dio();
  return WalletLevelsRemoteDataSource(dio);
});

// Repositories
final walletLevelsRepositoryProvider = Provider<WalletLevelsRepository>((ref) {
  final dataSource = ref.watch(walletLevelsDataSourceProvider);
  return WalletLevelsRepositoryImpl(dataSource);
});

// Use Cases
final getAllWalletLevelsUseCaseProvider =
    Provider<GetAllWalletLevelsUseCase>((ref) {
      final repository = ref.watch(walletLevelsRepositoryProvider);
      return GetAllWalletLevelsUseCase(repository);
    });

final getWalletLevelByTypeUseCaseProvider =
    Provider<GetWalletLevelByTypeUseCase>((ref) {
      final repository = ref.watch(walletLevelsRepositoryProvider);
      return GetWalletLevelByTypeUseCase(repository);
    });
