import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_tutorial_content.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/screens/pix_main_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/receive_pix_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/main_settings_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/converting_details_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/dev/raw_tx_dump_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/dev/swap_simulator_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_activity/asset_activity_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/holding_asset_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/home_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/new_transaction_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/qr_scanner_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/review_transaction_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/review_onchain_transaction_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive_funds/receive_funds_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive_funds/receive_qr_screen.dart';
import 'package:mooze_mobile/shared/widgets/bottom_nav_bar/custom_bottom_nav_bar.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class PageVisibilityProvider extends InheritedNotifier<ValueNotifier<int>> {
  PageVisibilityProvider({
    required ValueNotifier<int> currentPage,
    required this.pageFloat,
    required super.child,
    super.key,
  }) : super(notifier: currentPage);

  final ValueNotifier<double> pageFloat;

  static int? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageVisibilityProvider>()
        ?.notifier
        ?.value;
  }

  static ValueNotifier<double>? pageFloatOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageVisibilityProvider>()
        ?.pageFloat;
  }
}

class _MainNavigationScaffold extends ConsumerStatefulWidget {
  final String currentLocation;
  final Widget child;

  const _MainNavigationScaffold({
    required this.currentLocation,
    required this.child,
  });

  @override
  ConsumerState<_MainNavigationScaffold> createState() =>
      _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState
    extends ConsumerState<_MainNavigationScaffold> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<double> _pageFloatNotifier;
  bool _isPageChanging = false;

  // PIX onboarding tutorial (steps 1–2: home PIX button + bottom-nav button).
  TutorialCoachMark? _homeCoach;
  bool _homeCoachShown = false;
  // Guards the onFinish transition so the dispose-time finish() (cleanup)
  // doesn't re-fire it during widget-tree teardown. See ReceivePixScreen.
  bool _homeAdvancing = false;

  @override
  void initState() {
    super.initState();
    final initialPage = _getIndexFromLocation(widget.currentLocation);
    _pageController = PageController(initialPage: initialPage);
    _currentPageNotifier = ValueNotifier<int>(initialPage);
    _pageFloatNotifier = ValueNotifier<double>(initialPage.toDouble());
    _pageController.addListener(_onPageScroll);

    // Handle the case where the tutorial is already in its home stage by the
    // time the shell first builds (auto-start fires from HomeScreen.initState,
    // which runs in the same frame as this shell).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHomeTutorial());
  }

  /// Shows or hides the steps 1–2 coach mark to match the tutorial stage.
  void _syncHomeTutorial() {
    if (!mounted) return;
    final stage = ref.read(pixTutorialControllerProvider).stage;
    final onHomePage = _getIndexFromLocation(widget.currentLocation) == 0;

    if (stage == PixTutorialStage.home && onHomePage && !_homeCoachShown) {
      _homeCoachShown = true;
      final controller = ref.read(pixTutorialControllerProvider.notifier);
      showPixCoachMarkWhenReady(controller.homePixButtonKey, () {
        if (!mounted) return;
        _showHomeTutorial();
      }, label: 'home/pix-button');
    } else if (stage != PixTutorialStage.home) {
      // Reset so the tutorial can be re-shown on a future restart.
      _homeCoachShown = false;
    }
  }

  void _showHomeTutorial() {
    final controller = ref.read(pixTutorialControllerProvider.notifier);
    final t = AppLocalizations.of(context);

    _homeCoach = buildPixCoachMark(
      targets: [
        TargetFocus(
          identify: "pix_home_button",
          keyTarget: controller.homePixButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, coach) => pixTutorialContentCard(
                title: t.pix_tutorial_step1_title,
                body: t.pix_tutorial_step1_body,
                buttonLabel: t.common_next,
                onPressed: () => coach.next(),
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "pix_nav_button",
          keyTarget: controller.bottomNavPixKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, coach) => pixTutorialContentCard(
                title: t.pix_tutorial_step2_title,
                body: t.pix_tutorial_step2_body,
                buttonLabel: t.common_next,
                // Last target in this group — `next()` triggers `onFinish`.
                onPressed: () {
                  _homeAdvancing = true;
                  coach.next();
                },
              ),
            ),
          ],
        ),
      ],
      onFinish: () {
        // Only transition on genuine completion — dispose()'s finish() lands
        // here too.
        if (!_homeAdvancing) return;
        _homeAdvancing = false;
        // Advance to the receive group and bring the PIX page into view;
        // ReceivePixScreen picks up the `receive` stage and shows steps 3–7.
        controller.toReceive();
        if (_pageController.hasClients) {
          _pageController.jumpToPage(2);
        }
      },
      onSkip: _skipTutorial,
    );

    _homeCoach?.show(context: context);
  }

  /// Skipping the tutorial exits it and returns the user to Home (a no-op
  /// navigation when already there, but keeps Skip behaviour uniform).
  void _skipTutorial() {
    Future(() async {
      if (!mounted) return;
      await ref.read(pixTutorialControllerProvider.notifier).skip();
      if (mounted) context.go('/home');
    });
  }

  void _onPageScroll() {
    if (_pageController.position.isScrollingNotifier.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (_pageController.hasClients && _pageController.page != null) {
      final page = _pageController.page!;
      if (_pageFloatNotifier.value != page) {
        _pageFloatNotifier.value = page;
      }
      final currentPage = page.round();
      if (_currentPageNotifier.value != currentPage &&
          (page - currentPage).abs() < 0.1) {
        _currentPageNotifier.value = currentPage;
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _pageFloatNotifier.dispose();
    _homeCoach?.finish();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MainNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation &&
        !_isPageChanging) {
      final newIndex = _getIndexFromLocation(widget.currentLocation);
      if (_pageController.hasClients &&
          _pageController.page?.round() != newIndex) {
        _pageController.jumpToPage(newIndex);
      }

      if (newIndex == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncHomeTutorial();
        });
      }
    }
  }

  void _onPageChanged(int index) {
    if (_isPageChanging) return;

    _isPageChanging = true;
    final routes = ['/home', '/asset', '/pix', '/swap', '/menu'];
    if (index >= 0 && index < routes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(routes[index]);
          _isPageChanging = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromLocation(widget.currentLocation);

    // React to tutorial stage changes (auto-start, restart, advancing past
    // the home group) so the steps 1–2 coach mark appears/clears correctly.
    ref.listen<PixTutorialState>(pixTutorialControllerProvider, (_, _) {
      _syncHomeTutorial();
    });

    return PageVisibilityProvider(
      currentPage: _currentPageNotifier,
      pageFloat: _pageFloatNotifier,
      child: PlatformSafeArea(
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              const HomeScreen(),
              const HoldingsAsseetScreen(),
              // const PixMainScreen(),
              const ReceivePixScreen(),
              const SwapScreen(),
              const MainSettingsScreen(),
            ],
          ),
          extendBody: true,
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: CustomBottomNavBar(
            centralButtonKey:
                ref.read(pixTutorialControllerProvider.notifier).bottomNavPixKey,
            currentIndex: currentIndex,
            onTap: (index) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(index);
              }
            },
          ),
        ),
      ),
    );
  }
}

final walletRoutes = [
  // Live detail surface for an in-progress peg-in / peg-out. Reads
  // the optimistic row from `pendingSwapsProvider` by localId so the
  // screen updates as the phase machine advances; gracefully shows a
  // "completed" view when the reconciler retires the row mid-view.
  GoRoute(
    path: '/dev/swap-simulator',
    builder: (context, state) => const SwapSimulatorScreen(),
  ),
  GoRoute(
    path: '/dev/raw-tx-dump',
    builder: (context, state) => const RawTxDumpScreen(),
  ),
  GoRoute(
    path: '/swap/converting/:localId',
    builder: (context, state) {
      final localId = state.pathParameters['localId']!;
      return ConvertingDetailsScreen(localId: localId);
    },
  ),
  GoRoute(
    path: '/asset-activity',
    builder: (context, state) {
      final asset = state.extra as Asset;
      return AssetActivityScreen(asset: asset);
    },
  ),
  GoRoute(
    path: '/send-asset',
    builder: (context, state) => const NewTransactionScreen(),
  ),
  GoRoute(
    path: '/send-funds/review-simple',
    builder: (context, state) => const ReviewTransactionScreen(),
  ),
  GoRoute(
    path: '/send-funds/review-onchain',
    builder: (context, state) => const ReviewOnchainTransactionScreen(),
  ),
  GoRoute(
    path: '/send-funds/scanner',
    builder: (context, state) => const QRCodeScannerScreen(),
  ),
  GoRoute(
    path: '/receive-asset',
    builder: (context, state) => const ReceiveFundsScreen(),
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
            (context, state) => NoTransitionPage(child: PixMainScreen()),
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
