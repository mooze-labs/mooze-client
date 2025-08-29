import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/main_settings_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/presentation/screens/holding_asset_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/home_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/new_transaction_screen.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';

import '../swap/presentation/screens/swap_screen.dart';

class _MainNavigationScaffold extends StatefulWidget {
  final String currentLocation;
  final Widget child;

  const _MainNavigationScaffold({
    required this.currentLocation,
    required this.child,
  });

  @override
  State<_MainNavigationScaffold> createState() =>
      _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<_MainNavigationScaffold> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _getIndexFromLocation(widget.currentLocation),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MainNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _pageController.animateToPage(
        _getIndexFromLocation(widget.currentLocation),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    final routes = ['/home', '/asset', '/pix', '/swap', '/menu'];
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromLocation(widget.currentLocation);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const HomeScreen(),
          HoldingsAsseetScreen(),
          ReceivePixScreen(),
          const SwapScreen(),
          const MainSettingsScreen(),
        ],
      ),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          _pageController.jumpToPage(index);
          _onPageChanged(index);
        },
      ),
    );
  }
}

final walletRoutes = [
  GoRoute(
    path: '/send-asset',
    pageBuilder:
        (context, state) =>
            const NoTransitionPage(child: NewTransactionScreen()),
  ),

  ShellRoute(
    builder: (context, state, child) {
      final currentLocation = state.uri.toString();
      return _MainNavigationScaffold(
        currentLocation: currentLocation,
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) => NoTransitionPage(child: const HomeScreen()),
      ),
      GoRoute(
        path: '/asset',
        pageBuilder:
            (context, state) => NoTransitionPage(child: HoldingsAsseetScreen()),
      ),
      GoRoute(
        path: '/pix',
        pageBuilder:
            (context, state) => NoTransitionPage(child: ReceivePixScreen()),
      ),
      GoRoute(
        path: '/swap',
        pageBuilder:
            (context, state) => const NoTransitionPage(child: SwapScreen()),
      ),
      GoRoute(
        path: '/menu',
        pageBuilder:
            (context, state) =>
                const NoTransitionPage(child: MainSettingsScreen()),
      ),
    ],
  ),
];

int _getIndexFromLocation(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/asset')) return 1;
  if (location.startsWith('/pix')) return 2;
  if (location.startsWith('/swap')) return 3;
  if (location.startsWith('/menu')) return 4;
  return 0;
}
