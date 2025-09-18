import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/main_settings_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/holding_asset_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/home_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/new_transaction_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/qr_scanner_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/review_transaction_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive_funds/receive_funds_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive_funds/receive_qr_screen.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';

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
  GoRoute(
    path: '/send-funds/review-simple',
    builder: (context, state) => const ReviewTransactionScreen(),
  ),
  GoRoute(
    path: '/send-funds/scanner',
    builder: (context, state) => const QRCodeScannerScreen(),
  ),
  GoRoute(
    path: '/receive-asset',
    pageBuilder:
        (context, state) => const NoTransitionPage(child: ReceiveFundsScreen()),
  ),
  GoRoute(
    path: '/receive-qr',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return ReceiveQRScreen(
        qrData: extra['qrData'] as String,
        displayAddress: extra['displayAddress'] as String,
        asset: extra['asset'] as Asset,
        network: extra['network'] as NetworkType,
        amount: extra['amount'] as double?,
        description: extra['description'] as String?,
      );
    },
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
