import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../../providers/balance_provider.dart';
import '../../providers/send_funds/selected_asset_balance_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/selected_network_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/fee_speed_provider.dart';
import '../../widgets/send_funds/widgets.dart';

class NewTransactionScreen extends ConsumerWidget {
  const NewTransactionScreen({super.key});

  void _clearProviders(WidgetRef ref) {
    // Limpar endereço
    final addressController = ref.read(addressControllerProvider);
    addressController.clear();
    ref.invalidate(addressStateProvider);
    ref.invalidate(syncedAddressControllerProvider);

    // Limpar valores e conversões
    ref.invalidate(amountStateProvider);
    ref.invalidate(sendAssetValueProvider);
    ref.invalidate(sendSatsValueProvider);
    ref.invalidate(sendFiatValueProvider);
    ref.invalidate(sendConversionTypeProvider);
    ref.invalidate(sendConversionLoadingProvider);

    // Limpar seleções de asset e network
    ref.invalidate(selectedAssetProvider);
    ref.invalidate(selectedNetworkProvider);

    // Limpar detecções
    ref.invalidate(detectedAmountProvider);

    // Limpar velocidade de taxa
    ref.invalidate(feeSpeedProvider);

    // Limpar balances
    ref.invalidate(balanceProvider);
    ref.invalidate(selectedAssetBalanceProvider);
    ref.invalidate(selectedAssetBalanceRawProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _clearProviders(ref);
        }
      },
      child: AutoValidationListener(
        child: PlatformSafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Enviar ativos"),
              leading: IconButton(
                onPressed: () {
                  _clearProviders(ref);
                  context.pop();
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
              ),
              actions: [
                OfflineIndicator(
                  onTap: () => OfflinePriceInfoOverlay.show(context),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ).copyWith(top: 10, bottom: 24),
              child: Column(
                children: [
                  _buildInstructionText(context),
                  const SizedBox(height: 20),
                  AssetSelectorWidget(),
                  const SizedBox(height: 20),
                  BalanceCard(),
                  const SizedBox(height: 20),
                  AddressField(),
                  const SizedBox(height: 15),
                  NetworkIndicatorWidget(),
                  const SizedBox(height: 15),
                  ConditionalAmountField(),
                  const SizedBox(height: 15),
                  DrainInfoWidget(),
                  const SizedBox(height: 20),
                  FeeSpeedSelectionWidget(),
                  const SizedBox(height: 20),
                  ValidationErrorsWidget(),
                  FeeEstimationWidget(),
                  const SizedBox(height: 20),
                  ReviewButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            const TextSpan(text: "Escolha o ativo que quer enviar na "),
            TextSpan(
              text: "Mooze",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
