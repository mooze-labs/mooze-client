import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_section.dart';
import 'package:mooze_mobile/shared/widgets/update_notification_widget.dart';
import 'package:mooze_mobile/shared/providers/update_provider.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/sync_failure_alert.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/authentication/widgets/auth_initializer_widget.dart';
import 'package:mooze_mobile/shared/widgets/background_sync_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_indicators.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;
  Stopwatch? _mountStopwatch;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mountStopwatch = Stopwatch()..start();

    // Two-phase initial load. Phase 1 runs after the first frame and
    // touches only the V2 transaction notifier gate — cheap, non-blocking,
    // required for confirmation modals. Phase 2 (deferred ~250ms) prefetches
    // the price-history cache (the only cache provider actually consumed
    // by the home tree, via AssetGraphCard) and kicks the update check.
    // Balances/transactions are NOT touched here — they're driven by
    // `totalWalletValueProvider` (header) and `v2LegacyTransactionsProvider`
    // (list) which subscribe themselves the moment those widgets mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markNotifierHomeReached();
      _logMountTime();
      _scheduleDeferredLoads();
    });
  }

  /// Open the V2 transaction notifier's home-reached gate. Sticky for
  /// the session — flips `homeReached=true` so any pending or future
  /// confirmation events can surface as modals. Without this call the
  /// notifier holds events forever and the user never sees them.
  ///
  /// Best-effort: if the notifier is not yet constructed (rare race
  /// when /home is the first route the V2 boot resolves to), the
  /// future eventually completes and the call lands.
  void _markNotifierHomeReached() {
    ref
        .read(transactionNotifierProvider.future)
        .then((notifier) {
          notifier.setHomeReached();
        })
        .catchError((_) {
          /* notifier not ready — will be picked up on resume */
        });
  }

  void _logMountTime() {
    final sw = _mountStopwatch;
    if (sw == null) return;
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    final logger = ref.read(appLoggerProvider);
    logger.info('HomeScreen', 'first-frame ready in ${ms}ms');
    _mountStopwatch = null;
  }

  /// Defers the version-update check off the first frame. Price-history
  /// prefetch is NOT scheduled here — `AssetGraphCard.build` already
  /// triggers `fetchAssetPriceHistory(asset)` itself on a cache miss
  /// via its own post-frame callback, so duplicating the call here only
  /// causes redundant network work. Balances and transactions are
  /// driven by `totalWalletValueProvider` / `v2LegacyTransactionsProvider`
  /// which subscribe themselves when the header / list widgets mount.
  void _scheduleDeferredLoads() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _configureSystemUi();
    // Lightweight rebuild counter — fires periodically so a rebuild
    // storm is visible in the log feed without flooding on every
    // build (e.g. each balance/sync tick).
    _buildCount++;
    if (_buildCount % 10 == 0) {
      ref
          .read(appLoggerProvider)
          .info('HomeScreen', 'rebuild count: $_buildCount');
    }

    // Stale-while-revalidate: split the boot loader from the data loader.
    // Show the 3px top bar only during a true cold boot (`readyAt == null`)
    // OR while a background sync is actively running. After first ready,
    // re-entering the screen renders cached holdings/transactions
    // immediately because the underlying providers are no longer
    // `.autoDispose` and consumers use `skipLoadingOnRefresh: true`.
    final appState = ref.watch(appStateProvider).valueOrNull;
    final hasBootedOnce = appState?.readyAt != null;
    final syncPhase = ref.watch(syncStateProvider).valueOrNull?.phase;
    final isSyncing = syncPhase == SyncPhase.running;
    final isLoadingData = !hasBootedOnce || isSyncing;

    return AuthInitializerWidget(
      child: BackgroundSyncIndicator(
        child: Scaffold(
          // Debug-only entry point to the swap simulator. Compiled out
          // of release builds via the `kDebugMode` const, so end users
          // never see it. Lets you drive the optimistic peg-in /
          // peg-out row through every phase + the reconciler handoff
          // without paying real swap fees.
          floatingActionButton:
              kDebugMode
                  ? FloatingActionButton.small(
                    heroTag: 'dev-swap-sim',
                    tooltip: 'Swap simulator (dev)',
                    backgroundColor: Colors.deepPurple,
                    onPressed: () => context.push('/dev/swap-simulator'),
                    child: const Icon(Icons.bug_report, color: Colors.white),
                  )
                  : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          body: PlatformSafeArea(
            iosTop: true,
            androidTop: true,
            androidBottom: false,
            child: WalletScreenWrapper(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _refreshData(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LogoHeader(),
                            StatusIndicators(
                              onRetrySync: () {
                                ref.invalidate(ensureAuthSessionProvider);
                                ref.invalidate(levelsProvider);
                                ref.invalidate(walletLevelsProvider);
                                ref.invalidate(userDataProvider);
                                _refreshData();
                              },
                            ),
                            WalletHeaderWidget(),
                            UpdateNotificationWidget(),
                            const SizedBox(height: 15),
                            _buildActionButtons(),
                            const SizedBox(height: 32),
                            AssetSection(),
                            TransactionSection(),
                            SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isLoadingData)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadInitialData() {
    final updateNotifier = ref.read(updateNotifierProvider.notifier);
    updateNotifier.checkForUpdates();
  }

  Future<void> _refreshData() async {
    try {
      // Phase 2.3.3: routes through V2 `RefreshWalletUseCase(strategy: full)`.
      // Single-flight + mutex protection on the orchestrator side means
      // a concurrent periodic tick is automatically deduped — no
      // explicit `isSyncing` gate needed at the UI layer.
      final useCase = await ref.read(refreshWalletProvider.future);

      await Future.wait([
        useCase(strategy: SyncStrategy.full),
        ref.read(priceQuotesProvider.notifier).refresh(),
      ]);

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (_) {}
  }
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: ReceiveButton()),
          const SizedBox(width: 8),
          Expanded(child: SendButton()),
        ],
      ),
    ],
  );
}

void _configureSystemUi() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}
