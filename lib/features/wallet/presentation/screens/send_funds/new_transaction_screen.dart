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
import '../../providers/send_funds/send_funds_onboarding_service_provider.dart';
import '../../widgets/send_funds/widgets.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  ConsumerState<NewTransactionScreen> createState() =>
      _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  bool _hasCheckedFirstTimeDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkFirstTimeAccess();
      }
    });
  }

  Future<void> _checkFirstTimeAccess() async {
    if (_hasCheckedFirstTimeDialog) return;
    _hasCheckedFirstTimeDialog = true;

    final onboardingService = ref.read(sendFundsOnboardingServiceProvider);

    if (!onboardingService.hasSeenFirstTimeDialog() && mounted) {
      final router = GoRouter.of(context);
      final goToSwap = await LbtcDisclaimerDialog.show(context);

      if (!mounted) return;
      await onboardingService.markFirstTimeDialogAsSeen();
      // If the user tapped SWAP in the disclaimer, navigate there
      if (goToSwap == true) {
        router.go('/swap');
      }
    }
  }

  void _clearProviders(WidgetRef ref) {
    Future.microtask(() {
      // Guard against the widget being disposed before the microtask runs
      // (e.g. when context.go() navigates away and disposes this screen).
      if (!mounted) return;
      final addressController = ref.read(addressControllerProvider);
      addressController.clear();
      ref.invalidate(addressStateProvider);
      ref.invalidate(syncedAddressControllerProvider);

      ref.invalidate(amountStateProvider);
      ref.invalidate(sendAssetValueProvider);
      ref.invalidate(sendSatsValueProvider);
      ref.invalidate(sendFiatValueProvider);
      ref.invalidate(sendConversionTypeProvider);
      ref.invalidate(sendConversionLoadingProvider);

      ref.invalidate(selectedAssetProvider);
      ref.invalidate(selectedNetworkProvider);

      ref.invalidate(detectedAmountProvider);

      ref.invalidate(feeSpeedProvider);

      ref.invalidate(balanceProvider);
      ref.invalidate(selectedAssetBalanceProvider);
      ref.invalidate(selectedAssetBalanceRawProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                LbtcFeeInfoButton(),
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
                  LbtcZeroBalanceBanner(),
                  AddressField(),
                  const SizedBox(height: 10),
                  NetworkIndicatorWidget(),
                  const SizedBox(height: 10),
                  ConditionalAmountField(),
                  DrainInfoWidget(),
                  FeeSpeedSelectionWidget(),
                  ValidationErrorsWidget(),
                  FeeEstimationWidget(),
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
