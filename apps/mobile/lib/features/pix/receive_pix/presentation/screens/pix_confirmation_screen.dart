import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/pix_cpf_gate.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_fee_info_card.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/transaction_details_widget.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_qr_loading_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Review of a Pix deposit before the charge is created.
///
/// The screen shows what the user receives, the fees, and the deposit rules.
/// The user slides to confirm. The slide asks for the payer CPF when the
/// rules need it, then creates the charge and opens the payment screen.
class PixConfirmationScreen extends ConsumerStatefulWidget {
  /// Who pays the charge. The payer step uses the document of "my user"
  /// for the user's own deposit, and asks for another person's.
  final PixChargePayer payer;

  const PixConfirmationScreen({super.key, this.payer = PixChargePayer.self});

  @override
  ConsumerState<PixConfirmationScreen> createState() =>
      _PixConfirmationScreenState();
}

class _PixConfirmationScreenState extends ConsumerState<PixConfirmationScreen>
    with TickerProviderStateMixin {
  /// The scene that covers the screen while the charge is created.
  PixQrLoadingOverlay? _loading;
  bool _isLoading = false;

  // Fades and raises the content once, when the screen opens.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceController.isDismissed) {
      if (Motion.isReduced(context)) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    // A scene that is ending outlives the screen it uncovers.
    _loading?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    setState(() => _isLoading = true);

    // Temporary payer-CPF step (shared with the merchant flow). When the
    // requirement is disabled this is a no-op that proceeds with a null CPF.
    final cpfGate = await PixCpfGate.ensure(
      context,
      ref,
      payer: widget.payer,
    );
    if (!mounted) return;
    if (cpfGate.cancelled) {
      setState(() => _isLoading = false);
      return;
    }

    final loading = _loading = PixQrLoadingOverlay.show(
      context,
      text: AppLocalizations.of(context).pix_generating_qr,
    );

    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);
    final amountInCents = (depositAmount * 100).toInt();
    final minAnimationTime = Future.delayed(const Duration(milliseconds: 1500));

    try {
      final depositController = await ref.read(
        pixDepositControllerProvider.future,
      );
      final result = await depositController
          .newDeposit(
            amountInCents,
            selectedAsset,
            taxIdNumber: cpfGate.taxIdNumber,
          )
          .run();

      await minAnimationTime;

      result.fold(
        (err) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          loading.fail();
          AppSnackBar.error(context, err);
        },
        (deposit) {
          if (!mounted) return;

          setState(() => _isLoading = false);

          ref.read(depositAmountProvider.notifier).state = 0.0;
          ref.invalidate(feeRateProvider);
          ref.invalidate(feeAmountProvider);
          ref.invalidate(discountedFeesDepositProvider);
          ref.invalidate(assetQuoteProvider);

          // The code locks in, then the payment screen opens under the
          // scene. It replaces /pix/confirm in the stack so pop() from the
          // payment screen returns to /pix, not back here.
          loading.succeed(() {
            if (mounted) {
              context.pushReplacement("/pix/payment/${deposit.depositId}");
            }
          });
        },
      );
    } catch (e) {
      await minAnimationTime;
      if (!mounted) return;
      setState(() => _isLoading = false);
      loading.fail();
      AppSnackBar.error(context, humanizeError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);
    final canConfirm = depositAmount > 0 && validation.isValid;

    const gutter = PixScreenScaffold.gutter;

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      appBar: const BackdropAppBar(),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Stack(
                children: [
                  FadeSlideIn(
                    animation: CurvedAnimation(
                      parent: _entranceController,
                      curve: Motion.curveEnter,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              gutter,
                              8,
                              gutter,
                              16,
                            ),
                            children: [
                              PixScreenTitle(title: t.pix_confirm_title),
                              const SizedBox(height: 28),
                              TransactionDisplayWidget(),
                              const SizedBox(height: 16),
                              // The fee tiers and their footnotes: the
                              // terms of use place this disclosure on the
                              // confirmation screen.
                              const PixFeeInfoCard(),
                              const SizedBox(height: 28),
                              const InfoTipsSection(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            gutter,
                            8,
                            gutter,
                            12,
                          ),
                          child: SlideToConfirmButton(
                            text: t.wallet_slide_to_confirm,
                            isEnabled: canConfirm,
                            isLoading: _isLoading,
                            onSlideComplete: _onConfirm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ApiUnavailableOverlay(
                    onRetry: () {
                      ref.invalidate(pixDepositControllerProvider);
                    },
                    customMessage: t.pix_processing_unavailable,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
