import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_glass_button.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/utils/result.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Merchant Mode Exit Screen (Presentation Layer)
///
/// Confirmation screen displayed when exiting merchant mode.
///
/// Features:
/// - The logo and the question "Ready to sell?" on the screen backdrop
/// - "Receive new payment", the main action, back to Merchant Mode
/// - A glass button to the wallet. It asks for the PIN, deactivates
///   merchant mode, and navigates to the origin route (where user came
///   from) or home
///
/// Motion: the logo, the question, and the actions fade and rise in, one
/// after the other, inside [Motion.entranceBudget]. With reduced motion,
/// everything shows at once.
///
/// State Management:
/// - Uses merchant mode controller to deactivate mode
/// - Reads origin route to navigate back correctly
class MerchantModeExitScreen extends ConsumerStatefulWidget {
  const MerchantModeExitScreen({super.key});

  @override
  ConsumerState<MerchantModeExitScreen> createState() =>
      _MerchantModeExitScreenState();
}

class _MerchantModeExitScreenState extends ConsumerState<MerchantModeExitScreen>
    with SingleTickerProviderStateMixin {
  /// Logo, question, and actions.
  static const int _sections = 3;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Motion.staggeredEntrance(_sections),
  );
  late final List<Animation<double>> _sectionAnimations = [
    for (var index = 0; index < _sections; index++)
      staggeredAnimation(_entrance, index),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.isDismissed) {
      if (Motion.isReduced(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    for (final animation in _sectionAnimations) {
      if (animation is CurvedAnimation) animation.dispose();
    }
    _entrance.dispose();
    super.dispose();
  }

  /// Asks for the PIN, then leaves Merchant Mode for the route that opened
  /// it.
  Future<void> _backToWallet() async {
    // Get origin route using Clean Architecture use case
    final getOriginUseCase = ref.read(getMerchantModeOriginUseCaseProvider);
    final originResult = await getOriginUseCase();

    // Extract origin from Result using pattern matching
    String origin = '/home';
    if (originResult is Success<String>) {
      origin = originResult.data;
    }
    if (!mounted) return;

    context.push(
      '/setup/pin/verify',
      extra: VerifyPinArgs(
        onPinConfirmed: () async {
          // Deactivate merchant mode using Clean Architecture use case
          final deactivateUseCase = ref.read(
            deactivateMerchantModeUseCaseProvider,
          );
          await deactivateUseCase();

          // Clear cart
          ref.read(cartControllerProvider.notifier).clearCart();
          ref.invalidate(cartControllerProvider);
          if (!mounted) return;
          context.go(origin);
        },

        forceAuth: true,
        canGoBack: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            FadeSlideIn(
                              animation: _sectionAnimations[0],
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.92,
                                  end: 1,
                                ).animate(_sectionAnimations[0]),
                                child: Semantics(
                                  image: true,
                                  label: 'Mooze',
                                  excludeSemantics: true,
                                  // Only the width: with a height, the
                                  // package derives the width from it.
                                  child: SvgPicture.asset(
                                    'assets/logos/logo_primary.svg',
                                    width: 200,
                                    colorFilter: ColorFilter.mode(
                                      context.colors.logoColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FadeSlideIn(
                              animation: _sectionAnimations[1],
                              child: Semantics(
                                header: true,
                                child: Text(
                                  t.merchant_exit_ready,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The actions sit at the bottom, near the thumb, as the
                  // main buttons of the other flows.
                  FadeSlideIn(
                    animation: _sectionAnimations[2],
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Column(
                        children: [
                          PrimaryButton(
                            text: t.merchant_exit_new_payment,
                            onPressed: () {
                              context.go('/merchant');
                            },
                          ),
                          const SizedBox(height: 12),
                          MerchantGlassButton(
                            label: t.merchant_exit_back_to_wallet,
                            icon: PixIcons.deposit,
                            onPressed: _backToWallet,
                          ),
                        ],
                      ),
                    ),
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
