import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/wallet_level_entity.dart';
import '../../domain/entities/current_user_wallet_entity.dart';
import '../../domain/repositories/wallet_levels_repository.dart';
import '../../data/repositories/wallet_levels_repository_impl.dart';
import '../../data/datasources/wallet_levels_remote_data_source.dart';
import '../../../../shared/user/providers/user_service_provider.dart';

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

final walletLevelsProvider =
    FutureProvider.autoDispose<List<WalletLevelEntity>>((ref) async {
      final repository = ref.watch(walletLevelsRepositoryProvider);
      return repository.getAllWalletLevels();
    });

final walletLevelByTypeProvider = FutureProvider.autoDispose
    .family<WalletLevelEntity, WalletLevelType>((ref, type) async {
      final repository = ref.watch(walletLevelsRepositoryProvider);
      return repository.getWalletLevelByType(type);
    });

final currentUserWalletProvider =
    FutureProvider.autoDispose<CurrentUserWalletEntity>((ref) async {
      final userService = ref.watch(userServiceProvider);
      final result = await userService.getUser().run();

      return result.fold(
        (error) => throw Exception('Erro ao carregar dados do usuário: $error'),
        (user) {
          String levelName;
          switch (user.spendingLevel) {
            case 0:
              levelName = 'Bronze';
              break;
            case 1:
              levelName = 'Prata';
              break;
            case 2:
              levelName = 'Ouro';
              break;
            case 3:
              levelName = 'Diamante';
              break;
            default:
              levelName = 'Bronze';
          }

          return CurrentUserWalletEntity(
            currentLimit: user.dailySpending,
            maximumPossibleLimit: user.allowedSpending,
            minimumLimit: 20.0,
            currentLevel: levelName,
          );
        },
      );
    });
