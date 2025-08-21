import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/wallet_levels_screen.dart';

final walletLevelsRoutes = [
  GoRoute(
    path: "/wallet-levels",
    builder: (context, state) => const WalletLevelsScreen(),
  ),
];
