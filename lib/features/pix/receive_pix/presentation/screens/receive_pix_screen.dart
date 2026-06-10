import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_tutorial_content.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_dialog.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_dialog.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_value_input_widget.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen> {
  bool _hasShownFirstTimeDialog = false;

  TutorialCoachMark? _receiveCoach;
  bool _receiveCoachShown = false;
  bool _receiveAdvancing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!ref.read(pixTutorialControllerProvider).isActive) {
          ref.read(depositAmountProvider.notifier).state = 0.0;
        }
        ref.invalidate(feeRateProvider);
        ref.invalidate(feeAmountProvider);
        ref.invalidate(discountedFeesDepositProvider);
        ref.invalidate(assetQuoteProvider);

        _syncReceiveTutorial();
      }
    });
  }

  @override
  void dispose() {
    _receiveCoach?.finish();
    super.dispose();
  }

  /// Shows the steps 3–7 coach mark once the tutorial reaches the receive
  /// stage and the asset selector has been laid out.
  void _syncReceiveTutorial() {
    if (!mounted) return;
    final stage = ref.read(pixTutorialControllerProvider).stage;
    if (stage == PixTutorialStage.receive && !_receiveCoachShown) {
      _receiveCoachShown = true;
      final controller = ref.read(pixTutorialControllerProvider.notifier);
      showPixCoachMarkWhenReady(controller.assetSelectorKey, () {
        if (mounted) _showReceiveTutorial();
      }, label: 'receive/asset-selector');
    } else if (stage != PixTutorialStage.receive) {
      _receiveCoachShown = false;
    }
  }

  void _showReceiveTutorial() {
    final controller = ref.read(pixTutorialControllerProvider.notifier);
    final t = AppLocalizations.of(context);

    TargetFocus assetTarget(
      String identify,
      String title,
      String body, {
      void Function(TutorialCoachMarkController coach)? onNext,
    }) {
      return TargetFocus(
        identify: identify,
        keyTarget: controller.assetSelectorKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder:
                (context, coach) => pixTutorialContentCard(
                  title: title,
                  body: body,
                  buttonLabel: t.common_next,
                  onPressed: () =>
                      onNext != null ? onNext(coach) : coach.next(),
                ),
          ),
        ],
      );
    }

    _receiveCoach = buildPixCoachMark(
      targets: [
        // Step 3 & 4 — same target (asset selector), different copy. Advancing
        // to step 4 previews the L-BTC option so the user sees the selector can
        // change; advancing to step 5 restores the default dePIX asset.
        assetTarget(
          "pix_asset_default",
          t.pix_tutorial_step3_title,
          t.pix_tutorial_step3_body,
          onNext: (coach) {
            controller.previewLbtcAsset();
            coach.next();
          },
        ),
        assetTarget(
          "pix_asset_change",
          t.pix_tutorial_step4_title,
          t.pix_tutorial_step4_body,
          onNext: (coach) {
            controller.restoreDefaultAsset();
            coach.next();
          },
        ),
        // Step 5 — centered info (no specific element).
        TargetFocus(
          identify: "pix_swap_later",
          targetPosition: pixTutorialCenteredPosition(context),
          shape: ShapeLightFocus.RRect,
          radius: 20,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, coach) => pixTutorialContentCard(
                    title: t.pix_tutorial_step5_title,
                    body: t.pix_tutorial_step5_body,
                    buttonLabel: t.common_next,
                    onPressed: () => coach.next(),
                  ),
            ),
          ],
        ),
        // Step 6 — receiving limits.
        TargetFocus(
          identify: "pix_limits",
          keyTarget: controller.limitsKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, coach) => pixTutorialContentCard(
                    title: t.pix_tutorial_step6_title,
                    body: t.pix_tutorial_step6_body,
                    buttonLabel: t.common_next,
                    onPressed: () {
                      // Pre-fill the demo amount before highlighting the field.
                      controller.applyDemoAmount();
                      coach.next();
                    },
                  ),
            ),
          ],
        ),
        // Step 7 — amount input (last target → triggers onFinish).
        TargetFocus(
          identify: "pix_amount",
          keyTarget: controller.amountInputKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, coach) => pixTutorialContentCard(
                    title: t.pix_tutorial_step7_title,
                    body: t.pix_tutorial_step7_body,
                    buttonLabel: t.common_next,
                    onPressed: () {
                      _receiveAdvancing = true;
                      coach.next();
                    },
                  ),
            ),
          ],
        ),
      ],
      onFinish: () {
        // Only run the transition when the user actually completed the last
        // step — `finish()` from dispose() also lands here (see field doc).
        if (!_receiveAdvancing) {
          _receiveCoachShown = false;
          return;
        }
        _receiveAdvancing = false;
        // Advance to the confirmation surface (steps 8–9).
        controller.toConfirm();
        context.push('/pix/confirm');
      },
      onSkip: _skipTutorial,
    );

    _receiveCoach?.show(context: context);
  }

  /// Skipping the tutorial exits it and returns the user to Home.
  void _skipTutorial() {
    Future(() async {
      if (!mounted) return;
      await ref.read(pixTutorialControllerProvider.notifier).skip();
      if (mounted) context.go('/home');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPage = PageVisibilityProvider.of(context);
    if (!_hasShownFirstTimeDialog && currentPage == 2) {
      _hasShownFirstTimeDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkFirstTimeAccess();
      });
    }
    if (_hasShownFirstTimeDialog && currentPage != 2) {
      _hasShownFirstTimeDialog = false;
    }
  }

  Future<void> _checkFirstTimeAccess() async {
    // The onboarding tutorial takes precedence — don't stack the legacy
    // first-time dialog on top of the coach marks.
    if (ref.read(pixTutorialControllerProvider).isActive) return;

    final onboardingService = ref.read(pixOnboardingServiceProvider);

    if (!onboardingService.hasSeenFirstTimeDialog() && mounted) {
      final accepted = await FirstTimePixDialog.show(context);

      if (accepted == true && mounted) {
        await onboardingService.markFirstTimeDialogAsSeen();

        if (mounted) {
          await PixLimitsInfoDialog.show(context);
        }

        // await onboardingService.submitTermsAcceptance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // React to the tutorial reaching the receive stage (set by the shell when
    // the user finishes step 2 and the PIX page is brought into view).
    ref.listen<PixTutorialState>(pixTutorialControllerProvider, (_, _) {
      _syncReceiveTutorial();
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(t.pix_receive_appbar_title),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          IconButton(
            onPressed: () => _showPixInfo(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      bottomSheet: _buildKeyboardContinueButton(context),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(child: _buildBody(context)),
          ),
          ApiUnavailableOverlay(
            onRetry: () {
              ref.invalidate(depositAmountProvider);
            },
            customMessage: t.pix_receive_api_unavailable,
          ),
        ],
      ),
    );
  }

  void _advance() => context.push('/pix/confirm');

  Widget? _buildKeyboardContinueButton(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);
    final canContinue = depositAmount > 0 && validation.isValid;

    if (!isKeyboardVisible || !canContinue) return null;

    final t = AppLocalizations.of(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: PrimaryButton(text: t.pix_receive_advance, onPressed: _advance),
      ),
    );
  }

  void _showPixInfo(BuildContext context) {
    final t = AppLocalizations.of(context);
    InfoOverlay.show(
      context,
      title: t.pix_receive_info_title,
      steps: [
        InfoStep(
          icon: Icons.schedule,
          title: t.pix_receive_info_step1_title,
          description: t.pix_receive_info_step1_desc,
        ),
        InfoStep(
          icon: Icons.currency_bitcoin,
          title: t.pix_receive_info_step2_title,
          description: t.pix_receive_info_step2_desc,
        ),
        InfoStep(
          icon: Icons.receipt_long,
          title: t.pix_receive_info_step3_title,
          description: t.pix_receive_info_step3_desc,
        ),
      ],
      footerBuilder:
          (closeOverlay) => SecondaryButton(
            text: t.pix_receive_info_see_fees,
            onPressed: () {
              closeOverlay();
              context.push('/pix/fees');
            },
          ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: t.pix_receive_instruction_prefix,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(height: 1.4),
          children: [
            TextSpan(
              text: 'Mooze',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = AppLocalizations.of(context);
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);
    final isButtonEnabled = depositAmount > 0 && validation.isValid;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionText(context),
          const SizedBox(height: 10),
          KeyedSubtree(
            key:
                ref
                    .read(pixTutorialControllerProvider.notifier)
                    .assetSelectorKey,
            child: AssetSelectorWidget(),
          ),
          const SizedBox(height: 10),
          PixValueInputWidget(
            onContinue: _advance,
            amountKey:
                ref.read(pixTutorialControllerProvider.notifier).amountInputKey,
            limitsKey:
                ref.read(pixTutorialControllerProvider.notifier).limitsKey,
          ),
          const SizedBox(height: 12),
          InfoTipsSection(
            tips: [
              InfoTip(
                icon: Icons.trending_up_rounded,
                text: t.pix_receive_tip_more_payments,
                iconColor: const Color(0xFF2A9D6B),
              ),
            ],
            maxTips: 1,
          ),
          if (!isKeyboardVisible) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              text: t.pix_receive_advance,
              onPressed: _advance,
              isEnabled: isButtonEnabled,
            ),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
