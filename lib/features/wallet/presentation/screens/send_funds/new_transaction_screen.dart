import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../../providers/balance_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/fee_speed_provider.dart';
import '../../providers/send_funds/selected_asset_balance_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/selected_network_provider.dart';
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
      if (goToSwap == true) {
        router.go('/swap');
      }
    }
  }

  void _clearProviders(WidgetRef ref) {
    Future.microtask(() {
      if (!mounted) return;
      final addressController = ref.read(addressControllerProvider);
      addressController.clear();
      ref.invalidate(addressStateProvider);
      ref.invalidate(syncedAddressControllerProvider);

      ref.invalidate(amountStateProvider);
      ref.invalidate(maxSendRequestedProvider);
      ref.invalidate(sendConversionTypeProvider);

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
    final t = AppLocalizations.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearProviders(ref);
      },
      child: AutoValidationListener(
        child: PlatformSafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(t.wallet_send_appbar_title),
              leading: IconButton(
                onPressed: () {
                  _clearProviders(ref);
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              actions: [
                LbtcFeeInfoButton(),
                OfflineIndicator(
                  onTap: () => OfflinePriceInfoOverlay.show(context),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AssetSelectorWidget(),
                    SizedBox(height: 20),
                    BalanceCard(),
                    SizedBox(height: 28),
                    LbtcZeroBalanceBanner(),
                    AddressField(),
                    SizedBox(height: 12),
                    NetworkIndicatorWidget(),
                    SizedBox(height: 12),
                    ConditionalAmountField(),
                    DrainInfoWidget(),
                    SizedBox(height: 16),
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
      ),
    );
  }
}
