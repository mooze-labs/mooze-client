import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/swap/data/repositories/core_swap_repository.dart';
import 'package:mooze_mobile/features/swap/data/services/core_sideswap_session.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';

/// The mooze-core SideSwap connection. Swaps and pegs share it, so it
/// lives as long as the app.
final coreSideswapSessionProvider = Provider<CoreSideswapSession>((ref) {
  return CoreSideswapSession(core: ref.watch(moozeCoreProvider.future));
});

/// Swap repository for the swap screen. It is autoDispose: when no widget
/// watches `swapControllerProvider`, the repository stops the quote and
/// the core event stream. The connection stays open for the peg tracker.
final swapRepositoryProvider = FutureProvider.autoDispose<SwapRepository>((
  ref,
) async {
  final repository = CoreSwapRepository(
    session: ref.watch(coreSideswapSessionProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
