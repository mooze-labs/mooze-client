import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/new_ui_wallet/asset/presentation/widgets/action_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/presentation/widgets/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/providers/visibility_provider.dart';
import 'package:shimmer/shimmer.dart';

class HoldingsAsseetScreen extends ConsumerWidget {
  const HoldingsAsseetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const WalletHeaderWidget(),
            SizedBox(height: 15),
            _buildActionButtons(context),
            SizedBox(height: 15),
            _buildAssetsLabel(),
            SizedBox(height: 10),
            Expanded(child: _buildAssetsList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(title: Text('Ativos'));
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
            onPressed: () {},
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
          loading: () => _buildLoadingWidget(),
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

  Widget _buildLoadingWidget() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
