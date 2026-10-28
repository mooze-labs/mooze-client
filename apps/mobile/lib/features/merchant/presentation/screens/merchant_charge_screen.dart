import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/merchant_payment_method.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/merchant_payment_link_controller.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_link_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_method_screen.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/pix_cpf_gate.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/transaction_details_widget.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Merchant Charge Screen (Presentation Layer)
///
/// The payment/checkout screen for merchant mode transactions.
/// This screen is reached after the merchant clicks "Finalizar Venda" (Complete Sale)
/// from the merchant mode screen.
///
/// The confirm button opens [MerchantPaymentMethodScreen]. The merchant then
/// charges with a Pix QR Code or with a payment link.
///

class MerchantChargeScreen extends ConsumerStatefulWidget {
  /// Total amount to charge (in BRL)
  final double totalAmount;

  /// List of cart items being purchased
  final List<CartItemEntity> items;

  const MerchantChargeScreen({
    super.key,
    required this.totalAmount,
    required this.items,
  });

  @override
  ConsumerState<MerchantChargeScreen> createState() =>
      _MerchantChargeScreenState();
}

class _MerchantChargeScreenState extends ConsumerState<MerchantChargeScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;

  /// True while the payment method screen is open, so a second tap on
  /// the confirm button does not open it twice.
  bool _choosingMethod = false;

  /// True while the payment link request runs. Back is blocked meanwhile.
  bool _creatingLink = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeAccess();
      if (mounted) {
        ref.read(depositAmountProvider.notifier).state = widget.totalAmount;
      }
    });
  }

  void _initializeControllers() {
    _circleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _checkFirstTimeAccess() async {
    final onboardingService = ref.read(pixOnboardingServiceProvider);

    if (!await onboardingService.hasSeenMerchantFirstTimeDialog() &&
        mounted) {
      final accepted = await FirstTimePixDialog.show(context);

      if (accepted == true && mounted) {
        await onboardingService.markMerchantFirstTimeDialogAsSeen();

        if (mounted) {
          await PixLimitsInfoDialog.show(context);
        }

        // TODO: When there is an API, uncomment to sync with the backend
        // await onboardingService.submitTermsAcceptance();
      }
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    super.dispose();
  }

  /// Asks how the customer pays the confirmed amount, then runs that flow.
  void _onConfirm() async {
    if (_choosingMethod || _isLoading) return;
    _choosingMethod = true;
    final method = await MerchantPaymentMethodScreen.choose(
      context,
      amountInCents: _amountInCents,
      asset: ref.read(selectedAssetProvider),
    );
    _choosingMethod = false;
    if (!mounted || method == null) return;

    switch (method) {
      case MerchantPaymentMethod.pixQrCode:
        _startQrCodeFlow();
      case MerchantPaymentMethod.paymentLink:
        await _startPaymentLinkFlow();
    }
  }

  /// The confirmed sale amount in BRL cents.
  int get _amountInCents => (widget.totalAmount * 100).round();

  /// The link attempt of this sale. Keeping it alive while the screen is
  /// open lets a retry or a second visit reuse the same link.
  ProviderSubscription<MerchantPaymentLinkState>? _linkSubscription;
  MerchantPaymentLinkRequest? _linkRequest;

  MerchantPaymentLinkRequest _paymentLinkRequest() {
    final request = (
      amountInCents: _amountInCents,
      asset: ref.read(selectedAssetProvider),
    );
    if (request != _linkRequest) {
      _linkSubscription?.close();
      _linkRequest = request;
      _linkSubscription = ref.listenManual(
        merchantPaymentLinkControllerProvider(request),
        (_, _) {},
      );
    }
    return request;
  }

  /// Creates a payment link for the sale, with the loading animation of
  /// the QR Code flow. The link flow has no CPF step. When the merchant
  /// ends the sale on the link screen, this screen closes too.
  Future<void> _startPaymentLinkFlow() async {
    if (_isLoading) return;
    final t = AppLocalizations.of(context);
    final request = _paymentLinkRequest();
    final provider = merchantPaymentLinkControllerProvider(request);

    var link = ref.read(provider).link;
    final created = link == null;
    if (created) {
      setState(() {
        _isLoading = true;
        _creatingLink = true;
      });
      _showLoadingOverlay(t.merchant_payment_link_creating);
      _playLoadingAnimation();
      final minAnimationTime = Future.delayed(
        const Duration(milliseconds: 1500),
      );
      await ref.read(provider.notifier).create();
      await minAnimationTime;
      if (!mounted) return;

      final state = ref.read(provider);
      link = state.link;
      setState(() {
        _isLoading = false;
        _creatingLink = false;
      });
      if (link == null) {
        _hideLoadingOverlay();
        _circleController.reset();
        _showPaymentLinkFailure(state.failure);
        return;
      }
    }

    final finished = MerchantPaymentLinkScreen.open(
      context,
      link: link,
      request: request,
      playReveal: created,
    );
    // The link screen covers the overlay with its reveal, as in the QR flow.
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _hideLoadingOverlay();

    final done = await finished;
    if (!mounted) return;
    _circleController.reset();
    if (done) Navigator.of(context).pop();
  }

  /// Tells why the link was not created. A retry repeats the same request.
  void _showPaymentLinkFailure(PixHubFailure? failure) {
    final t = AppLocalizations.of(context);
    final code = failure?.code ?? PixHubErrorCode.unknown;
    // Waiting does not change these answers, so they offer no retry.
    final retryable =
        code != PixHubErrorCode.notEligible &&
        code != PixHubErrorCode.amountOutOfBounds;
    AppSnackBar.show(
      context,
      message: pixHubFailureMessage(t, failure ?? PixHubFailure(code)),
      type: SnackBarType.error,
      action: retryable
          ? SnackBarAction(
              label: t.common_retry,
              onPressed: _startPaymentLinkFlow,
            )
          : SnackBarAction(label: t.common_ok, onPressed: () {}),
    );
  }

  /// The Pix QR Code flow: payer CPF, deposit, then the QR Code screen.
  void _startQrCodeFlow() async {
    setState(() => _isLoading = true);

    // Temporary payer-CPF step (shared with the Pix flow).
    final cpfGate = await PixCpfGate.ensure(context, ref);
    if (!mounted) return;
    if (cpfGate.cancelled) {
      setState(() => _isLoading = false);
      return;
    }

    _showLoadingOverlay();
    _playLoadingAnimation();

    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);

    final amountInCents = (depositAmount * 100).toInt();

    final minAnimationTime = Future.delayed(Duration(milliseconds: 1500));

    try {
      final controller = await ref.read(pixDepositControllerProvider.future);
      final result =
          await controller
              .newDeposit(
                amountInCents,
                selectedAsset,
                taxIdNumber: cpfGate.taxIdNumber,
              )
              .run();

      await minAnimationTime;

      result.fold(
        (err) {
          if (mounted) {
            setState(() => _isLoading = false);
            _hideLoadingOverlay();
            _circleController.reset();

            AppSnackBar.show(
              context,
              message: err,
              type: SnackBarType.error,
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            );
          }
        },
        (deposit) async {
          if (!mounted) return;

          setState(() => _isLoading = false);

          context.push("/pix/payment/${deposit.depositId}").then((_) {
            if (mounted) {
              _circleController.reset();
              ref.read(depositAmountProvider.notifier).state =
                  widget.totalAmount;
              ref.invalidate(pixDepositControllerProvider);
              ref.invalidate(feeRateProvider);
              ref.invalidate(feeAmountProvider);
              ref.invalidate(discountedFeesDepositProvider);
              ref.invalidate(assetQuoteProvider);
            }
          });

          await Future.delayed(Duration(milliseconds: 200));
          if (mounted) {
            _hideLoadingOverlay();
          }
        },
      );
    } catch (e) {
      await minAnimationTime;
      if (!mounted) return;
      setState(() => _isLoading = false);
      _hideLoadingOverlay();
      _circleController.reset();

      AppSnackBar.show(
        context,
        message: humanizeError(context, e),
        type: SnackBarType.error,
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      );
    }
  }

  /// Shows the loading animation. [text] defaults to the QR Code text.
  void _showLoadingOverlay([String? text]) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => LoadingOverlayWidget(
            circleController: _circleController,
            circleAnimation: _circleAnimation,
            loadingText: text ?? AppLocalizations.of(context).pix_generating_qr,
            showLoadingText: true,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Grows the pink circle of the loading overlay. With reduced motion, the
  /// overlay covers the screen at once.
  void _playLoadingAnimation() {
    if (Motion.isReduced(context)) {
      _circleController.value = 1;
    } else {
      _circleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final validation = ref.watch(
      merchantValidationProvider(widget.totalAmount),
    );
    final notice = validation.isValid ? null : validation.localizedMessage(t);

    return PopScope(
      canPop: !_creatingLink,
      child: MerchantFlowScaffold(
        title: t.merchant_charge_receive_title,
        subtitle: '${t.merchant_charge_instruction_prefix}Mooze.',
        amountInCents: _amountInCents,
        // The limit notice grows in below the amount when the limits load.
        amountCaption: notice == null ? null : _AmountNotice(message: notice),
        bottomAction: PrimaryButton(
          text: t.common_continue,
          isLoading: _isLoading,
          isEnabled: validation.isValid,
          onPressed: _onConfirm,
        ),
        overlay: ApiUnavailableOverlay(
          showBackButton: true,
          onBack: () => context.pop(),
          onRetry: () {
            ref.invalidate(pixDepositControllerProvider);
            ref.invalidate(depositAmountProvider);
          },
          customMessage: t.pix_processing_unavailable,
        ),
        children: [
          AssetSelectorWidget(),
          const SizedBox(height: 20),
          TransactionDisplayWidget(),
          const SizedBox(height: 32),
          PixSectionHeader(title: t.merchant_items_section),
          const SizedBox(height: 12),
          _SaleItemsPanel(items: widget.items),
          const SizedBox(height: 32),
          PixSectionHeader(title: t.pix_receive_my_limits),
          const SizedBox(height: 12),
          const _LimitsPanel(),
        ],
      ),
    );
  }
}

/// Tells why the amount cannot be charged, for example a limit.
///
/// The warning icon and the text carry the state, so it never depends on
/// color alone. Only the icon has the warning color: as text, the light
/// warning colors stay under 4.5:1 on the page. Screen readers announce
/// the message when it appears.
class _AmountNotice extends StatelessWidget {
  const _AmountNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.warning;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PixIcon(PixIcons.warning, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The items of the sale in one glass panel, split by hairlines.
class _SaleItemsPanel extends StatelessWidget {
  const _SaleItemsPanel({required this.items});

  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const PanelDivider(),
              _SaleItemRow(item: items[index]),
            ],
          ],
        ),
      ),
    );
  }
}

/// One item: the name, the quantity and unit price, and the line total.
class _SaleItemRow extends StatelessWidget {
  const _SaleItemRow({required this.item});

  final CartItemEntity item;

  /// Largest part of the row that the line total can take.
  static const double _maxTotalShare = 0.45;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    final t = AppLocalizations.of(context);
    final unitCents = merchantCents(item.price);
    final detail =
        '${t.merchant_qty_prefix(item.quantity)} · ${formatBrlCents(unitCents)}';
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * _maxTotalShare,
                ),
                child: Text(
                  formatBrlCents(unitCents * item.quantity),
                  textAlign: TextAlign.end,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Pix limits of the user, as on the deposit screen.
///
/// While the limits load, the values say so. When they fail, the panel
/// keeps the fixed daily limit and offers a retry.
class _LimitsPanel extends ConsumerWidget {
  const _LimitsPanel();

  static String _reais(double amount) => formatBrlCents(merchantCents(amount));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final daily = PixSummaryEntry(
      t.merchant_limit_daily,
      _reais(UserLevelsData.dailyLimit),
    );

    return ref
        .watch(levelsProvider)
        .when(
          data: (data) => PixSummaryCard(
            entries: [
              daily,
              PixSummaryEntry(
                t.merchant_limit_per_transaction,
                _reais(data.allowedSpending),
              ),
              PixSummaryEntry(
                t.merchant_limit_min,
                _reais(data.absoluteMinLimit),
              ),
            ],
          ),
          loading: () => PixSummaryCard(
            entries: [
              PixSummaryEntry(t.merchant_limit_daily, t.common_loading),
              PixSummaryEntry(
                t.merchant_limit_per_transaction,
                t.common_loading,
              ),
              PixSummaryEntry(t.merchant_limit_min, t.common_loading),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixSummaryCard(entries: [daily]),
              const SizedBox(height: 12),
              _LimitsError(
                details: humanizeError(context, error),
                onRetry: () {
                  ref.invalidate(walletLevelsRemoteProvider);
                  ref.invalidate(userDataProvider);
                },
              ),
            ],
          ),
        );
  }
}

/// Says that the limits did not load, with a retry.
class _LimitsError extends StatelessWidget {
  const _LimitsError({required this.details, required this.onRetry});

  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: PixIcon(PixIcons.warning, size: 18, color: warning),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).merchant_limits_load_error,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
            minimumSize: const Size(48, 48),
          ),
          icon: PixIcon(
            PixIcons.refresh,
            size: 16,
            color: context.colors.textPrimary,
          ),
          label: Text(AppLocalizations.of(context).common_retry),
        ),
      ],
    );
  }
}
