import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:mooze_mobile/shared/infra/sync/sync_failure_widgets.dart';
import 'package:mooze_mobile/shared/authentication/widgets/auth_initializer_widget.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_indicators.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataFromCache();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialDataFromCache() {
    if (!mounted) return;

    final transactionCache = ref.read(transactionHistoryCacheProvider.notifier);
    final balanceCache = ref.read(balanceCacheProvider.notifier);
    final assetPriceCache = ref.read(assetPriceHistoryCacheProvider.notifier);

    if (ref.read(transactionHistoryCacheProvider).transactions == null) {
      transactionCache.fetchTransactionsInitial();
    }

    final mainAssets = [Asset.lbtc, Asset.btc, Asset.usdt];
    for (final asset in mainAssets) {
      if (ref.read(balanceCacheProvider).balances[asset] == null) {
        balanceCache.fetchBalanceInitial(asset);
      }
    }

    for (final asset in mainAssets) {
      if (ref.read(assetPriceHistoryCacheProvider).priceHistory[asset] ==
          null) {
        assetPriceCache.fetchAssetPriceHistoryInitial(asset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _configureSystemUi();

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
      child: Scaffold(
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
      await useCase(strategy: SyncStrategy.full);

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
