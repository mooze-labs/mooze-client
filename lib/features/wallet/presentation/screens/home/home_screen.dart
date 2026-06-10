import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/action_button.dart';
import 'package:mooze_mobile/shared/widgets/update_notification_widget.dart';
import 'package:mooze_mobile/shared/providers/update_provider.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/authentication/widgets/auth_initializer_widget.dart';
import 'package:mooze_mobile/shared/widgets/background_sync_indicator.dart';
import 'package:mooze_mobile/shared/widgets/wallet_loading_banner.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_indicators.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
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
      _maybeStartPixTutorial();
    });
  }

  void _maybeStartPixTutorial() {
    if (!mounted) return;
    final controller = ref.read(pixTutorialControllerProvider.notifier);
    final alreadyActive = ref.read(pixTutorialControllerProvider).isActive;
    if (!alreadyActive && !controller.hasSeen) {
      controller.start();
    }
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
          // Debug-only entry point: long-press to open the raw-tx dump
          // (BDK + LWK + Breez + V2 store), tap to open the swap
          // simulator. Compiled out of release builds via `kDebugMode`.
          floatingActionButton:
              kDebugMode
                  ? FloatingActionButton.small(
                    heroTag: 'dev-tools',
                    tooltip: 'Tap: swap simulator · Long-press: raw tx dump',
                    backgroundColor: Colors.deepPurple,
                    onPressed: () => context.push('/dev/swap-simulator'),
                    child: GestureDetector(
                      onLongPress: () => context.push('/dev/raw-tx-dump'),
                      child: const Icon(Icons.bug_report, color: Colors.white),
                    ),
                  )
                  : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          body: PlatformSafeArea(
            iosTop: true,
            androidTop: true,
            androidBottom: false,
            child: RefreshIndicator(
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
                          ref.invalidate(walletLevelsProvider);
                          ref.invalidate(userDataProvider);
                          _refreshData();
                        },
                      ),
                      WalletLoadingBanner(
                        isVisible: isLoadingData,
                        label:
                            AppLocalizations.of(
                              context,
                            ).wallet_import_msg_loading_transactions,
                      ),
                      WalletHeaderWidget(),
                      UpdateNotificationWidget(),
                      const SizedBox(height: 15),
                      _buildActionButtons(
                        context,
                        pixButtonKey: ref
                            .read(pixTutorialControllerProvider.notifier)
                            .homePixButtonKey,
                      ),
                      const SizedBox(height: 32),
                      AssetSection(),
                      TransactionSection(),
                      SizedBox(height: 120),
                    ],
                  ),
                ),
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

Widget _buildActionButtons(BuildContext context, {Key? pixButtonKey}) {
  final t = AppLocalizations.of(context);
  return Row(
    children: [
      Expanded(
        child: ActionButton(
          svgAsset: 'assets/icons/menu/send.svg',
          label: t.wallet_holding_action_send,
          onPressed: () {
            context.push('/send-asset');
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ActionButton(
          svgAsset: 'assets/icons/menu/receive.svg',
          label: t.wallet_holding_action_receive,
          onPressed: () {
            context.push('/receive-asset');
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ActionButton(
          key: pixButtonKey,
          svgAsset: 'assets/icons/menu/navigation/pix.svg',
          label: t.wallet_action_buy,
          isPrimary: true,
          onPressed: () => context.go('/pix'),
        ),
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
