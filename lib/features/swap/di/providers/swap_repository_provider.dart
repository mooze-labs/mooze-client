import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
import 'package:mooze_mobile/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:mooze_mobile/features/swap/data/repositories/liquid_wallet_repository_impl.dart';
import 'package:mooze_mobile/features/swap/domain/repositories.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_store_provider.dart';

const String _sideswapApiKey = String.fromEnvironment(
  'SIDESWAP_API_KEY',
  defaultValue:
      '5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1',
);

// All sideswap providers are autoDispose so the SideSwap WebSocket
// connection follows the swap-screen lifecycle exactly: when no
// widget is watching `swapControllerProvider` (e.g. the user has
// navigated away from the swap tab and we've short-circuited the
// build), the whole chain tears down — controller → repository →
// service → api → WebSocketService. The WS sends `close(normal)`
// to SideSwap, cancels its reconnect/idle timers, and frees its
// stream subscriptions. No zombie sockets, no looping reconnects.
//
// Re-entering the swap tab triggers a fresh watch which lazily
// reconstructs the whole chain — a brand-new WS handshake, no
// reused state from the previous session.
final sideswapApiProvider = Provider.autoDispose<SideswapApi>((ref) {
  final api = SideswapApi();
  ref.onDispose(api.dispose);
  return api;
});

final sideswapServiceProvider = Provider.autoDispose<SideswapService>((ref) {
  final api = ref.watch(sideswapApiProvider);
  final service = SideswapService(api: api, apiKey: _sideswapApiKey);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

final swapWalletProvider = FutureProvider.autoDispose<SwapWallet>((ref) async {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  final walletRepo = await ref.read(walletRepositoryProvider.future);
  return LiquidWalletRepositoryImpl(
    walletRepository: walletRepo,
    mnemonicStore: mnemonicStore,
  );
});

final swapRepositoryProvider = FutureProvider.autoDispose<SwapRepository>((
  ref,
) async {
  final wallet = await ref.read(swapWalletProvider.future);
  // `watch` (not `read`) — keeps the sideswap service alive as
  // long as this repository is alive, and propagates teardown
  // when the service provider goes away.
  final service = ref.watch(sideswapServiceProvider);
  return SwapRepositoryImpl(sideswapService: service, liquidWallet: wallet);
});
