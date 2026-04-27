import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_fee_info_card.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/transaction_details_widget.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class PixConfirmationScreen extends ConsumerStatefulWidget {
  const PixConfirmationScreen({super.key});

  @override
  ConsumerState<PixConfirmationScreen> createState() =>
      _PixConfirmationScreenState();
}

class _PixConfirmationScreenState extends ConsumerState<PixConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    super.dispose();
  }

  void _onSlideComplete() async {
    setState(() => _isLoading = true);
    _showLoadingOverlay();
    _circleController.forward();

    final controller = await ref.read(pixDepositControllerProvider.future);
    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);
    final amountInCents = (depositAmount * 100).toInt();
    final minAnimationTime = Future.delayed(const Duration(milliseconds: 1500));

    controller.fold(
      (err) async {
        await minAnimationTime;
        if (!mounted) return;
        setState(() => _isLoading = false);
        _hideLoadingOverlay();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
        _circleController.reset();
      },
      (depositController) async {
        final result =
            await depositController
                .newDeposit(amountInCents, selectedAsset)
                .run();

        await minAnimationTime;

        result.fold(
          (err) async {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _hideLoadingOverlay();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(err)));
            _circleController.reset();
          },
          (deposit) async {
            if (!mounted) return;

            setState(() => _isLoading = false);

            ref.read(depositAmountProvider.notifier).state = 0.0;
            ref.invalidate(feeRateProvider);
            ref.invalidate(feeAmountProvider);
            ref.invalidate(discountedFeesDepositProvider);
            ref.invalidate(assetQuoteProvider);

            // Replace /pix/confirm in the stack so pop() from the payment
            // screen returns to /pix, not back here.
            context.pushReplacement("/pix/payment/${deposit.depositId}");

            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              _hideLoadingOverlay();
            }
          },
        );
      },
    );
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => LoadingOverlayWidget(
            circleController: _circleController,
            circleAnimation: _circleAnimation,
            loadingText: AppLocalizations.of(context).pix_generating_qr,
            showLoadingText: true,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);
    final isSlideEnabled =
        depositAmount > 0 && validation.isValid && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pix_confirm_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 8, left: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TransactionDisplayWidget(),
                    const SizedBox(height: 16),
                    const PixFeeInfoCard(),
                    const SizedBox(height: 16),
                    const InfoTipsSection(),
                    const SizedBox(height: 24),
                    SlideToConfirmButton(
                      onSlideComplete: _onSlideComplete,
                      text: t.merchant_generate_qr,
                      isLoading: _isLoading,
                      isEnabled: isSlideEnabled,
                    ),
                  ],
                ),
              ),
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
    );
  }
}
