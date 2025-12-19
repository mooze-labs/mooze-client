import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
import 'package:mooze_mobile/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:mooze_mobile/features/swap/data/repositories/liquid_wallet_repository_impl.dart';
import 'package:mooze_mobile/features/swap/domain/repositories.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/sync/sync_controller.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

const String _sideswapApiKey = String.fromEnvironment(
  'SIDESWAP_API_KEY',
  defaultValue:
      '5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1',
);

final sideswapApiProvider = Provider.autoDispose<SideswapApi>((ref) {
  final api = SideswapApi();
  ref.onDispose(() {
    api.dispose();
  });
  return api;
});

final sideswapServiceProvider = Provider.autoDispose<SideswapService>((ref) {
  final api = ref.watch(sideswapApiProvider);
  final service = SideswapService(api: api, apiKey: _sideswapApiKey);
  service.init();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final swapWalletProvider = FutureProvider.autoDispose<SwapWallet>((ref) async {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  final dsEither = await ref.read(liquidDataSourceProvider.future);
  final syncState = ref.watch(walletSyncControllerProvider.notifier);
  return dsEither.match(
    (err) => throw Exception('Erro ao inicializar carteira Liquid: $err'),
    (ds) => LiquidWalletRepositoryImpl(
      wallet: ds,
      mnemonicStore: mnemonicStore,
      syncController: syncState,
    ),
  );
});

final swapRepositoryProvider = FutureProvider.autoDispose<SwapRepository>((
  ref,
) async {
  final wallet = await ref.read(swapWalletProvider.future);
  final service = ref.read(sideswapServiceProvider);
  return SwapRepositoryImpl(sideswapService: service, liquidWallet: wallet);
});
