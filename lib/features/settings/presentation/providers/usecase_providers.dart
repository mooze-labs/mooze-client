import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/domain/repositories/account_unit_repository.dart';
import 'package:mooze_mobile/features/settings/domain/repositories/blockchain_settings_repository.dart';
import 'package:mooze_mobile/features/settings/domain/usecases/get_account_unit_usecase.dart';
import 'package:mooze_mobile/features/settings/domain/usecases/get_node_url_usecase.dart';
import 'package:mooze_mobile/features/settings/domain/usecases/set_account_unit_usecase.dart';
import 'package:mooze_mobile/features/settings/domain/usecases/set_node_url_usecase.dart';
import 'package:mooze_mobile/features/settings/external/datasources/account_unit_local_datasource.dart';
import 'package:mooze_mobile/features/settings/external/datasources/bitcoin_settings_local_datasource.dart';
import 'package:mooze_mobile/features/settings/external/datasources/liquid_settings_local_datasource.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/account_unit_datasource.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/blockchain_settings_datasource.dart';
import 'package:mooze_mobile/features/settings/infra/repositories/account_unit_repository_impl.dart';
import 'package:mooze_mobile/features/settings/infra/repositories/blockchain_settings_repository_impl.dart';

/// Settings Dependency Injection Container
/// Clean Architecture: External -> Infra -> Domain -> Presentation

// Data Sources
final accountUnitDataSourceProvider = Provider<AccountUnitDataSource>((ref) {
  return AccountUnitLocalDataSource();
});

final bitcoinSettingsDataSourceProvider =
    Provider<BlockchainSettingsDataSource>((ref) {
  return BitcoinSettingsLocalDataSource();
});

final liquidSettingsDataSourceProvider =
    Provider<BlockchainSettingsDataSource>((ref) {
  return LiquidSettingsLocalDataSource();
});

// Repositories
final accountUnitRepositoryProvider = Provider<AccountUnitRepository>((ref) {
  final dataSource = ref.watch(accountUnitDataSourceProvider);
  return AccountUnitRepositoryImpl(dataSource);
});

final bitcoinSettingsRepositoryProvider =
    Provider<BlockchainSettingsRepository>((ref) {
  final dataSource = ref.watch(bitcoinSettingsDataSourceProvider);
  return BlockchainSettingsRepositoryImpl(dataSource);
});

final liquidSettingsRepositoryProvider =
    Provider<BlockchainSettingsRepository>((ref) {
  final dataSource = ref.watch(liquidSettingsDataSourceProvider);
  return BlockchainSettingsRepositoryImpl(dataSource);
});

// Account Unit Use Cases
final getAccountUnitUseCaseProvider = Provider<GetAccountUnitUseCase>((ref) {
  final repository = ref.watch(accountUnitRepositoryProvider);
  return GetAccountUnitUseCase(repository);
});

final setAccountUnitUseCaseProvider = Provider<SetAccountUnitUseCase>((ref) {
  final repository = ref.watch(accountUnitRepositoryProvider);
  return SetAccountUnitUseCase(repository);
});

// Bitcoin Node URL Use Cases
final getBitcoinNodeUrlUseCaseProvider = Provider<GetNodeUrlUseCase>((ref) {
  final repository = ref.watch(bitcoinSettingsRepositoryProvider);
  return GetNodeUrlUseCase(repository);
});

final setBitcoinNodeUrlUseCaseProvider = Provider<SetNodeUrlUseCase>((ref) {
  final repository = ref.watch(bitcoinSettingsRepositoryProvider);
  return SetNodeUrlUseCase(repository);
});

// Liquid Node URL Use Cases
final getLiquidNodeUrlUseCaseProvider = Provider<GetNodeUrlUseCase>((ref) {
  final repository = ref.watch(liquidSettingsRepositoryProvider);
  return GetNodeUrlUseCase(repository);
});

final setLiquidNodeUrlUseCaseProvider = Provider<SetNodeUrlUseCase>((ref) {
  final repository = ref.watch(liquidSettingsRepositoryProvider);
  return SetNodeUrlUseCase(repository);
});
