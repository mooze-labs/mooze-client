import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_sheet.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_unavailable_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/pix_value_input_widget.dart';

/// Amount step of the Pix deposit (`/pix/deposit`).
///
/// The screen follows the Pix hub: the backdrop behind a clear app bar, a
/// large title, the asset choice as a compact row, the amount as the hero,
/// and the limits in one glass summary. The main action stays pinned at the
/// bottom, above the keyboard.
///
/// With [PixChargePayer.someoneElse] the same steps make a charge that
/// another person pays: the titles say so, and the payer step asks for that
/// person's document.
class ReceivePixScreen extends ConsumerStatefulWidget {
  final PixChargePayer payer;

  const ReceivePixScreen({super.key, this.payer = PixChargePayer.self});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen> {
  bool _hasShownFirstTimeDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(depositAmountProvider.notifier).state = 0.0;
        ref.invalidate(feeRateProvider);
        ref.invalidate(feeAmountProvider);
        ref.invalidate(discountedFeesDepositProvider);
        ref.invalidate(assetQuoteProvider);
      }
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
    final onboardingService = ref.read(pixOnboardingServiceProvider);

    if (!await onboardingService.hasSeenFirstTimeDialog() && mounted) {
      final accepted = await FirstTimePixSheet.show(context);

      if (accepted == true && mounted) {
        await onboardingService.markFirstTimeDialogAsSeen();

        if (mounted) {
          await PixLimitsInfoSheet.show(context);
        }

        // await onboardingService.submitTermsAcceptance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);
    final canContinue = depositAmount > 0 && validation.isValid;
    final forSomeoneElse = widget.payer == PixChargePayer.someoneElse;

    // The overlay starts below the app bar, so the back button stays usable
    // while the API is down.
    final appBarBottom = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: BackdropAppBar(
        title: Text(forSomeoneElse ? '' : t.pix_hub_shortcut_deposit),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          IconButton(
            tooltip: t.pix_receive_info_title,
            onPressed: () => _showPixInfo(context),
            // Neutral: the brand color stays on the main action.
            icon: PixIcon(
              PixIcons.info,
              size: 22,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: _ContentEntrance(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          PixScreenScaffold.gutter,
                          8,
                          PixScreenScaffold.gutter,
                          16,
                        ),
                        children: [
                          PixScreenTitle(
                            title: forSomeoneElse
                                ? t.pix_hub_receive_qr
                                : t.pix_hub_info_deposit_title,
                            // The brand name is not translated.
                            subtitle: forSomeoneElse
                                ? t.pix_hub_receive_qr_subtitle
                                : '${t.pix_receive_instruction_prefix}Mooze.',
                          ),
                          const SizedBox(height: 16),
                          const AssetSelectorWidget(),
                          const SizedBox(height: 20),
                          PixValueInputWidget(onContinue: _advance),
                          const SizedBox(height: 14),
                          InfoTipsSection(
                            tips: [
                              InfoTip(
                                pixIcon: PixIcons.trendingUp,
                                text: t.pix_receive_tip_more_payments,
                              ),
                            ],
                            maxTips: 1,
                          ),
                        ],
                      ),
                    ),
                    // One main action, pinned above the keyboard.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PixScreenScaffold.gutter,
                        8,
                        PixScreenScaffold.gutter,
                        12,
                      ),
                      child: PrimaryButton(
                        text: t.pix_receive_advance,
                        onPressed: _advance,
                        isEnabled: canContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: appBarBottom,
            child: ApiUnavailableOverlay(
              onRetry: () {
                ref.invalidate(depositAmountProvider);
              },
              customMessage: t.pix_receive_api_unavailable,
            ),
          ),
        ],
      ),
    );
  }

  void _advance() => context.push('/pix/confirm${widget.payer.query}');

  /// Opens the guidance about deposits in a glass sheet.
  void _showPixInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DepositInfoSheet(
        onSeeFees: () {
          Navigator.of(sheetContext).pop();
          context.push('/pix/fees');
        },
      ),
    );
  }
}

/// Guidance about deposits: processing time, the L-BTC rate, and the fees.
class _DepositInfoSheet extends StatelessWidget {
  final VoidCallback onSeeFees;

  const _DepositInfoSheet({required this.onSeeFees});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final steps = [
      (
        icon: PixIcons.clock,
        title: t.pix_receive_info_step1_title,
        body: t.pix_receive_info_step1_desc,
      ),
      (
        icon: PixIcons.trendingUp,
        title: t.pix_receive_info_step2_title,
        body: t.pix_receive_info_step2_desc,
      ),
      (
        icon: PixIcons.receipt,
        title: t.pix_receive_info_step3_title,
        body: t.pix_receive_info_step3_desc,
      ),
    ];

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      t.pix_receive_info_title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.common_close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: PixIcon(
                    PixIcons.close,
                    size: 20,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final step in steps) ...[
                    if (step != steps.first) const SizedBox(height: 18),
                    MergeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PixIconWell(icon: step.icon, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: context.textTheme.bodyLarge?.copyWith(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  step.body,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SecondaryButton(
                    text: t.pix_receive_info_see_fees,
                    onPressed: onSeeFees,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and raises the content once, when the screen opens.
///
/// It matches the entrance of [PixScreenScaffold]. With reduced motion the
/// content appears at once.
class _ContentEntrance extends StatefulWidget {
  const _ContentEntrance({required this.child});

  final Widget child;

  @override
  State<_ContentEntrance> createState() => _ContentEntranceState();
}

class _ContentEntranceState extends State<_ContentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}
