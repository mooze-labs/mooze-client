import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/action_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_loading.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/shared/widgets/wallet_loading_banner.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';

class HoldingsAsseetScreen extends ConsumerStatefulWidget {
  const HoldingsAsseetScreen({super.key});

  @override
  ConsumerState<HoldingsAsseetScreen> createState() =>
      _HoldingsAsseetScreenState();
}

class _HoldingsAsseetScreenState extends ConsumerState<HoldingsAsseetScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: WalletLoadingBanner(
              isVisible: isLoadingData,
              label: t.wallet_import_msg_loading_transactions,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshData(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const WalletHeaderWidget(),
                      SizedBox(height: 15),
                      _buildActionButtons(context),
                      SizedBox(height: 15),
                      ValuesToReceiveCard(),
                      _buildAssetsLabel(),
                      SizedBox(height: 10),
                      _buildAssetsList(),
                    ],
                  ),
                ),
              ),
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
    _resetScrollToTop();
  }

  Future<void> _resetScrollToTop() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.offset == 0) return;
    try {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // `animateTo` can throw if the controller detaches mid-flight.
    }
    if (mounted &&
        _scrollController.hasClients &&
        _scrollController.offset != 0) {
      _scrollController.jumpTo(0);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final t = AppLocalizations.of(context);
    return AppBar(
      title: Text(t.wallet_holding_appbar_title),
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            icon: Icons.send,
            label: t.wallet_holding_action_send,
            onPressed: () {
              context.push('/send-asset');
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ActionButton(
            icon: Icons.qr_code_scanner,
            label: t.wallet_holding_action_receive,
            onPressed: () {
              context.push('/receive-asset');
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ActionButton(
            icon: Icons.swap_horiz,
            label: t.wallet_holding_action_swap,
            onPressed: () {
              context.go('/swap');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsLabel() {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          t.wallet_holding_appbar_title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
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
        return holdingsAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data:
              (holdingsResult) => holdingsResult.fold(
                (error) => _buildErrorWidget(error),
                (holdings) => _buildHoldingsList(holdings),
              ),
          loading: () => AssetLoading(),
          error:
              (error, stack) => _buildErrorWidget(
                t.wallet_holding_unexpected_error('$error'),
              ),
        );
      },
    );
  }

  Widget _buildHoldingsList(List<WalletHolding> holdings) {
    final t = AppLocalizations.of(context);
    if (holdings.isEmpty) {
      return Center(child: Text(t.wallet_holding_empty));
    }

    return Consumer(
      builder: (context, ref, child) {
        final isVisible = ref.watch(isVisibleProvider);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: holdings.length,
          itemBuilder: (context, index) {
            final holding = holdings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: InkWell(
                onTap:
                    () => context.push('/asset-activity', extra: holding.asset),
                child: AssetTransactionItem(
                  icon: holding.asset.iconPath,
                  title: holding.asset.name,
                  subtitle: isVisible ? '•••••' : holding.formattedBalance,
                  value: isVisible ? '•••••' : holding.formattedFiatValue,
                  time:
                      isVisible
                          ? ''
                          : (holding.hasBalance
                              ? ''
                              : t.wallet_holding_no_balance),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            t.wallet_holding_load_error_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
