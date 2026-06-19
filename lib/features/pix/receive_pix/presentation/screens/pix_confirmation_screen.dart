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
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/pix_cpf_gate.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_tutorial_content.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );

    // The tutorial stage is already `confirm` when this screen is pushed
    // (set by ReceivePixScreen), so trigger from initState rather than
    // relying on a listener change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncConfirmTutorial());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _circleController.dispose();
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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
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
        // Step 8 — the slide-to-generate button.
        TargetFocus(
          identify: "pix_slide_button",
          keyTarget: controller.slideButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder:
                  (context, coach) => pixTutorialContentCard(
                    title: t.pix_tutorial_step8_title,
                    body: t.pix_tutorial_step8_body,
                    buttonLabel: t.common_next,
                    onPressed: () => coach.next(),
                  ),
            ),
          ],
        ),
        // Step 9 — QR ready (simulated; does not trigger the real slide).
        TargetFocus(
          identify: "pix_qr_ready",
          targetPosition: pixTutorialCenteredPosition(context),
          shape: ShapeLightFocus.RRect,
          radius: 20,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
              ),
              builder:
                  (context, coach) => pixTutorialContentCard(
                    title: t.pix_tutorial_step9_title,
                    body: t.pix_tutorial_step9_body,
                    buttonLabel: t.common_finish,
                    onPressed: () {
                      _confirmAdvancing = true;
                      coach.next();
                    },
                    center: true,
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
    _circleController.forward();

    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);
    final amountInCents = (depositAmount * 100).toInt();
    final minAnimationTime = Future.delayed(const Duration(milliseconds: 1500));

    try {
      final depositController = await ref.read(
        pixDepositControllerProvider.future,
      );
      final result =
          await depositController
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
      AppSnackBar.error(context, e.toString());
      _circleController.reset();
    }
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
    final isConfirmEnabled =
        depositAmount > 0 && validation.isValid && !_isLoading;

    final tutorialActive = ref.watch(pixTutorialControllerProvider).isActive;

    return AbsorbPointer(
      absorbing: tutorialActive,
      child: Scaffold(
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
                  padding: const EdgeInsets.only(
                    right: 8,
                    left: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TransactionDisplayWidget(),
                      const SizedBox(height: 16),
                      const PixFeeInfoCard(),
                      const SizedBox(height: 16),
                      const InfoTipsSection(),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        key:
                            ref
                                .read(pixTutorialControllerProvider.notifier)
                                .slideButtonKey,
                        onPressed: isConfirmEnabled ? _onConfirm : null,
                        text: t.common_continue,
                        isLoading: _isLoading,
                        isEnabled: isConfirmEnabled,
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
      ),
    );
  }
}
