import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_downgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_upgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/wallet_levels_screen.dart';

final walletLevelsRoutes = [
  GoRoute(
    path: "/wallet-levels",
    builder: (context, state) => const WalletLevelsScreen(),
  ),
  GoRoute(
    path: "/level-upgrade",
    builder: (context, state) {
      final oldLevel = state.uri.queryParameters['oldLevel'];
      final newLevel = state.uri.queryParameters['newLevel'];

      return LevelUpgradeScreen(
        oldLevel: int.parse(oldLevel ?? '1'),
        newLevel: int.parse(newLevel ?? '2'),
      );
    },
  ),
  GoRoute(
    path: "/level-downgrade",
    builder: (context, state) {
      final oldLevel = state.uri.queryParameters['oldLevel'];
      final newLevel = state.uri.queryParameters['newLevel'];

      return LevelDowngradeScreen(
        oldLevel: int.parse(oldLevel ?? '2'),
        newLevel: int.parse(newLevel ?? '1'),
      );
    },
  ),
];
