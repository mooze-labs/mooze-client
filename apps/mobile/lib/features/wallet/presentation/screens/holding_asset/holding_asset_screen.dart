import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/allocation_bar.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_loading.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/portfolio_history_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/balance_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/home_action_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/section_header.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/refresh_scroll_view.dart';
import 'package:mooze_mobile/shared/widgets/status_island.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Side margin of the holdings content.
const double _holdingsMargin = 20;

class HoldingsAsseetScreen extends ConsumerStatefulWidget {
  const HoldingsAsseetScreen({super.key});

  @override
  ConsumerState<HoldingsAsseetScreen> createState() =>
      _HoldingsAsseetScreenState();
}

class _HoldingsAsseetScreenState extends ConsumerState<HoldingsAsseetScreen> {
  final _pull = PullRefreshController();

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider).valueOrNull;
    final hasBootedOnce = appState?.readyAt != null;
    final syncPhase = ref.watch(syncStateProvider).valueOrNull?.phase;
    final isSyncing = syncPhase == SyncPhase.running;
    final isLoadingData = !hasBootedOnce || isSyncing;

    final t = AppLocalizations.of(context);
    // The app bar and the body share the backdrop of the main screens. The
    // body starts at the top of the screen, below the transparent bar.
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(loading: isLoadingData),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: RefreshScrollView(
                    controller: _pull,
                    onRefresh: _refreshData,
                    // The bottom space keeps the last row above the
                    // navigation bar.
                    padding: const EdgeInsets.fromLTRB(
                      _holdingsMargin,
                      8,
                      _holdingsMargin,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A tap on the change chip opens the history of the
                        // portfolio.
                        const BalanceHero(
                          onVariationTap: showPortfolioHistorySheet,
                        ),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                        const SizedBox(height: 24),
                        ValuesToReceiveCard(),
                        // The app bar already says "Assets". The section
                        // shows how the total splits between the assets.
                        SectionHeader(title: t.wallet_holding_allocation_title),
                        _buildAssetsList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      // Phase 2.3.3: routes through V2 `RefreshWalletUseCase(strategy: full)`.
      final useCase = await ref.read(refreshWalletProvider.future);
      await useCase(strategy: SyncStrategy.full);
    } catch (e) {
      debugPrint('Erro durante refresh: $e');
    }
  }

  PreferredSizeWidget _buildAppBar({required bool loading}) {
    final t = AppLocalizations.of(context);
    final offline = ref.watch(isUsingCacheProvider);
    return BackdropAppBar(
      title: Text(t.wallet_holding_appbar_title),
      actions: [
        // The island is the indicator of the pull-to-refresh too.
        ListenableBuilder(
          listenable: _pull,
          builder: (context, _) => StatusIsland(
            alignment: Alignment.centerRight,
            offline: offline,
            loading: loading || _pull.refreshing,
            pull: _pull.progress,
            loadingLabel: t.status_island_sync,
            loadingSemanticsLabel: t.wallet_import_msg_loading_transactions,
            onOfflineTap: () => OfflinePriceInfoOverlay.show(context),
          ),
        ),
        const SizedBox(width: _holdingsMargin),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return HomeActionRow(
      onSend: () {
        context.push('/send-asset');
      },
      onReceive: () {
        context.push('/receive-asset');
      },
      onSwap: () {
        context.go('/swap');
      },
    );
  }

  Widget _buildAssetsList() {
    return Consumer(
      builder: (context, ref, child) {
        final t = AppLocalizations.of(context);
        final holdingsAsync = ref.watch(walletHoldingsProvider);

        // `skipLoadingOnRefresh`/`skipLoadingOnReload` keep rendering the
        // previous holdings list while the provider re-runs in the
        // background (e.g. after a V2 sync tick or pull-to-refresh). The
        // skeleton only appears on the very first cold load, when no
        // cached value exists yet.
        final content = holdingsAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (holdingsResult) => holdingsResult.fold(
            (error) => KeyedSubtree(
              key: const ValueKey('error'),
              child: _buildErrorWidget(error),
            ),
            (holdings) => KeyedSubtree(
              key: const ValueKey('data'),
              child: _buildHoldingsList(holdings),
            ),
          ),
          loading: () => const AssetLoading(key: ValueKey('loading')),
          error: (error, stack) => KeyedSubtree(
            key: const ValueKey('error'),
            child: _buildErrorWidget(
              t.wallet_holding_unexpected_error('$error'),
            ),
          ),
        );

        // The skeleton cross-fades to the content. Value updates keep the
        // same key and do not cross-fade.
        return AnimatedSwitcher(
          duration: Motion.of(context, Motion.durationBase),
          switchInCurve: Motion.curveMove,
          switchOutCurve: Motion.curveMove,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: content,
        );
      },
    );
  }

  /// The portfolio panel: the allocation at the top, then one row per
  /// holding. The legend carries the shares, so the rows stay lean.
  Widget _buildHoldingsList(List<WalletHolding> holdings) {
    final t = AppLocalizations.of(context);
    if (holdings.isEmpty) {
      return Center(child: Text(t.wallet_holding_empty));
    }

    // Shares of the total fiat value, largest first. Rank 0 takes the brand
    // color in the bar and in the legend.
    final valued = [
      for (final holding in holdings)
        if ((holding.fiatValue ?? 0) > 0) holding,
    ]..sort((a, b) => b.fiatValue!.compareTo(a.fiatValue!));
    final total = valued.fold<double>(0, (sum, h) => sum + h.fiatValue!);

    return Consumer(
      builder: (context, ref, child) {
        // `isVisibleProvider` is true when the balance is hidden.
        final isHidden = ref.watch(isVisibleProvider);

        // A Liquid Glass panel: tint, sheen, edge glow, and rim, without a
        // backdrop blur. The panel sits on the fixed screen backdrop, so a
        // blur would cost every scroll frame and show nothing.
        return GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (total > 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A hidden balance hides the composition: the bar
                      // shows equal neutral parts and the legend masks the
                      // shares.
                      AllocationBar(
                        segments: [
                          for (var i = 0; i < valued.length; i++)
                            AllocationSegment(
                              share: isHidden
                                  ? 1 / valued.length
                                  : valued[i].fiatValue! / total,
                              color: isHidden
                                  ? AppSurfaces.hairline(context)
                                  : allocationColor(context, i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AllocationLegend(
                        isHidden: isHidden,
                        entries: [
                          for (var i = 0; i < valued.length; i++)
                            AllocationEntry(
                              label: valued[i].asset.ticker,
                              share: valued[i].fiatValue! / total,
                              color: allocationColor(context, i),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              // Each row is the origin of its activity sheet. The origin
              // covers the row's whole slice of the panel: the hairline
              // above it and, at the ends, the panel corners. The sheet
              // then opens from, and closes into, the row as it looks.
              for (var i = 0; i < holdings.length; i++)
                GlassSheetOrigin(
                  borderRadius: _rowSliceRadius(
                    first: i == 0 && total <= 0,
                    last: i == holdings.length - 1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (i > 0)
                        const PanelDivider(
                          indent: AssetTransactionItem.textInset,
                        )
                      else if (total > 0)
                        const PanelDivider(),
                      Builder(
                        builder: (context) => MergeSemantics(
                          // No ripple and no press highlight: the sheet
                          // grows out of the row, and the row stays as it
                          // is.
                          child: InkWell(
                            onTap: () => showAssetActivitySheet(
                              context,
                              asset: holdings[i].asset,
                            ),
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                            child: AssetTransactionItem(
                              icon: holdings[i].asset.iconPath,
                              title: holdings[i].asset.name,
                              ticker: holdings[i].asset.ticker,
                              balance: holdings[i].formattedBalance,
                              value: holdings[i].formattedFiatValue,
                              fiatValue: holdings[i].fiatValue,
                              // A muted "R\$ 0,00" already says "no balance".
                              muted: !holdings[i].hasBalance,
                              isHidden: isHidden,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Corners of a row's slice of the panel: the panel corners at the top of
  /// the [first] slice and at the bottom of the [last] slice.
  static BorderRadius _rowSliceRadius({
    required bool first,
    required bool last,
  }) {
    const corner = AppSurfaces.panelRadius;
    return BorderRadius.only(
      topLeft: first ? corner.topLeft : Radius.zero,
      topRight: first ? corner.topRight : Radius.zero,
      bottomLeft: last ? corner.bottomLeft : Radius.zero,
      bottomRight: last ? corner.bottomRight : Radius.zero,
    );
  }

  Widget _buildErrorWidget(String error) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: context.colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            t.wallet_holding_load_error_title,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
