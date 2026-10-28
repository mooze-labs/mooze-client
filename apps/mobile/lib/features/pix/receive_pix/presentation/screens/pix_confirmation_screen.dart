import 'package:flutter/material.dart';
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
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_tutorial_content.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_fee_info_card.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/transaction_details_widget.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Review of a Pix deposit before the charge is created.
///
/// The screen shows what the user receives, the fees, and the deposit rules.
/// The main action asks for the payer CPF when the rules need it, then
/// creates the charge and opens the payment screen.
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

  // Fades and raises the content once, when the screen opens.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );

  // PIX onboarding tutorial (steps 8–9: slide button + QR ready).
  TutorialCoachMark? _confirmCoach;
  bool _confirmCoachShown = false;
  // Guards the onFinish completion-modal so dispose()'s finish() (cleanup)
  // doesn't re-fire it during teardown. See ReceivePixScreen.
  bool _confirmAdvancing = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      duration: Motion.durationCelebrate,
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Motion.curveEnter),
    );

    // The tutorial stage is already `confirm` when this screen is pushed
    // (set by ReceivePixScreen), so trigger from initState rather than
    // relying on a listener change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncConfirmTutorial());
  }

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
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
    _entranceController.dispose();
    _confirmCoach?.finish();
    super.dispose();
  }

  void _syncConfirmTutorial() {
    if (!mounted) return;
    final stage = ref.read(pixTutorialControllerProvider).stage;
    if (stage == PixTutorialStage.confirm && !_confirmCoachShown) {
      _confirmCoachShown = true;
      final controller = ref.read(pixTutorialControllerProvider.notifier);
      showPixCoachMarkWhenReady(controller.slideButtonKey, () async {
        final buttonContext = controller.slideButtonKey.currentContext;
        if (buttonContext != null) {
          await Scrollable.ensureVisible(
            buttonContext,
            alignment: 0.5,
            duration: Motion.of(buttonContext, Motion.durationEmphasis),
            curve: Motion.curveMove,
          );
        }
        if (mounted) _showConfirmTutorial();
      }, label: 'confirm/slide-button');
    }
  }

  void _showConfirmTutorial() {
    final controller = ref.read(pixTutorialControllerProvider.notifier);
    final t = AppLocalizations.of(context);

    _confirmCoach = buildPixCoachMark(
      targets: [
        // Final step — the slide-to-generate button.
        TargetFocus(
          identify: "pix_slide_button",
          keyTarget: controller.slideButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, coach) => pixTutorialContentCard(
                title: t.pix_tutorial_step8_title,
                body: t.pix_tutorial_step8_body,
                buttonLabel: t.common_finish,
                onPressed: () {
                  _confirmAdvancing = true;
                  coach.next();
                },
              ),
            ),
          ],
        ),
      ],
      onFinish: () {
        // Only show the completion modal on genuine completion —
        // dispose()'s finish() lands here too.
        if (!_confirmAdvancing) return;
        _confirmAdvancing = false;
        _showCompletionModal();
      },
      onSkip: _skipTutorial,
    );

    _confirmCoach?.show(context: context);
  }

  /// Skipping the tutorial exits it and returns the user to Home. Deferred and
  /// mutate-before-navigate for the same reasons as the completion modal.
  void _skipTutorial() {
    Future(() async {
      if (!mounted) return;
      await ref.read(pixTutorialControllerProvider.notifier).skip();
      if (mounted) context.go('/home');
    });
  }

  void _showCompletionModal() {
    PixTutorialCompletionModal.show(
      context,
      onFinish: () {
        Future(() async {
          if (!mounted) return;
          await ref.read(pixTutorialControllerProvider.notifier).finish();
          if (mounted) context.go('/home');
        });
      },
      onRestart: () {
        Future(() {
          if (!mounted) return;
          ref.read(pixTutorialControllerProvider.notifier).restart();
          if (mounted) context.go('/home');
        });
      },
    );
  }

  void _onConfirm() async {
    setState(() => _isLoading = true);

    // Temporary payer-CPF step (shared with the merchant flow). When the
    // requirement is disabled this is a no-op that proceeds with a null CPF.
    final cpfGate = await PixCpfGate.ensure(context, ref);
    if (!mounted) return;
    if (cpfGate.cancelled) {
      setState(() => _isLoading = false);
      return;
    }

    _showLoadingOverlay();
    // With reduced motion, the circle covers the screen at once.
    if (Motion.isReduced(context)) {
      _circleController.value = 1;
    } else {
      _circleController.forward();
    }

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
        (err) async {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _hideLoadingOverlay();
          AppSnackBar.error(context, err);
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
    } catch (e) {
      await minAnimationTime;
      if (!mounted) return;
      setState(() => _isLoading = false);
      _hideLoadingOverlay();
      AppSnackBar.error(context, humanizeError(context, e));
      _circleController.reset();
    }
  }

  void _showLoadingOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => LoadingOverlayWidget(
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
    final isConfirmEnabled =
        depositAmount > 0 && validation.isValid && !_isLoading;

    final tutorialActive = ref.watch(pixTutorialControllerProvider).isActive;
    const gutter = PixScreenScaffold.gutter;

    return AbsorbPointer(
      absorbing: tutorialActive,
      child: Scaffold(
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
                            child: PrimaryButton(
                              key: ref
                                  .read(pixTutorialControllerProvider.notifier)
                                  .slideButtonKey,
                              onPressed: isConfirmEnabled ? _onConfirm : null,
                              text: t.common_continue,
                              isLoading: _isLoading,
                              isEnabled: isConfirmEnabled,
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
      ),
    );
  }
}
