import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/action_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_loading.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/shared/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

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
    final isLoadingData = ref.watch(isLoadingDataProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          RefreshIndicator(
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
                    _buildAssetsLabel(),
                    SizedBox(height: 10),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 300,
                      child: _buildAssetsList(),
                    ),
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
    );
  }

  Future<void> _refreshData() async {
    try {
      final walletDataManager = ref.read(walletDataManagerProvider.notifier);
      await walletDataManager.refreshWalletData();

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      debugPrint('Erro durante refresh: $e');
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Ativos'),
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            icon: Icons.send,
            label: 'Enviar',
            onPressed: () {
              context.push('/send-asset');
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Receber',
            onPressed: () {
              context.push('/receive-asset');
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ActionButton(
            icon: Icons.swap_horiz,
            label: 'Swap',
            onPressed: () {
              context.go('/swap');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsLabel() {
    return Row(
      children: [
        Text(
          'Ativos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsList() {
    return Consumer(
      builder: (context, ref, child) {
        final holdingsAsync = ref.watch(walletHoldingsProvider);

        return holdingsAsync.when(
          data:
              (holdingsResult) => holdingsResult.fold(
                (error) => _buildErrorWidget(error),
                (holdings) => _buildHoldingsList(holdings),
              ),
          loading: () => AssetLoading(),
          error: (error, stack) => _buildErrorWidget('Erro inesperado: $error'),
        );
      },
    );
  }

  Widget _buildHoldingsList(List<WalletHolding> holdings) {
    if (holdings.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum ativo encontrado',
          style: TextStyle(color: Colors.white70),
        ),
      );
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
              child: AssetTransactionItem(
                icon: holding.asset.iconPath,
                title: holding.asset.name,
                subtitle: isVisible ? '•••••' : holding.formattedBalance,
                value: isVisible ? '•••••' : holding.formattedFiatValue,
                time: isVisible ? '' : (holding.hasBalance ? '' : 'Sem saldo'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar ativos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
