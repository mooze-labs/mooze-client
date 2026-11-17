import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_glass_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_shop_scene.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/header.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/route_entrance.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_haptics.dart';
import 'package:mooze_mobile/shared/utils/result.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Merchant Mode Exit Screen (Presentation Layer)
///
/// Confirmation screen displayed when exiting merchant mode.
///
/// Features:
/// - The shop opening (see [MerchantShopScene]) and the question "Ready to
///   sell?" on the screen backdrop. A tap on the shop turns it once.
/// - "Receive new payment", the main action, back to Merchant Mode
/// - A glass button to the wallet. It asks for the PIN, deactivates
///   merchant mode, and navigates to the origin route (where user came
///   from) or home
///
/// Motion: the scene starts once the page is in place. The question fades
/// and rises in as the lights of the shop turn on, with a light haptic,
/// and the actions follow. With reduced motion, the scene shows at rest
/// and everything shows at once.
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
    with TickerProviderStateMixin, StageHaptics<MerchantModeExitScreen> {
  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: MerchantShopScene.duration,
  );

  /// The shop after a tap.
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: Motion.durationShopTap,
  )..addListener(_onTapTick);

  /// Whether the lights of the shop turned on again after the last tap.
  bool _relit = true;

  late final Animation<double> _question = _reveal(0.4, 0.7);
  late final Animation<double> _actions = _reveal(0.5, 0.8);

  bool _started = false;

  /// Fades in between the moments [begin] and [end] of the entrance of the
  /// scene.
  Animation<double> _reveal(double begin, double end) => CurvedAnimation(
    parent: _scene,
    curve: Interval(
      MerchantShopScene.atEntrance(begin),
      MerchantShopScene.atEntrance(end),
      curve: Motion.curveEnter,
    ),
  );

  @override
  Animation<double> get stageAnimation => _scene;

  @override
  List<StageBeat> get stageBeats => [
    (
      at: MerchantShopScene.atEntrance(MerchantShopScene.lightsOn),
      play: HapticFeedback.lightImpact,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _scene.value = 1;
    } else {
      afterRouteEntrance(context, _scene.forward);
    }
  }

  @override
  void dispose() {
    for (final animation in [_question, _actions]) {
      if (animation is CurvedAnimation) animation.dispose();
    }
    _scene.dispose();
    _tap.dispose();
    super.dispose();
  }

  /// Turns the shop once. Under reduced motion, only the haptic answers.
  void _onShopTap() {
    if (_tap.isAnimating) return;
    if (Motion.isReduced(context)) {
      HapticFeedback.lightImpact();
      return;
    }
    _relit = false;
    _tap.forward(from: 0);
  }

  void _onTapTick() {
    if (_relit || _tap.value < MerchantShopScene.tapLightsOn) return;
    _relit = true;
    HapticFeedback.lightImpact();
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
                  // The logo at the top, as on the home screen.
                  const LogoHeader(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        // The light and the shockwave of the shop cross the
                        // whole screen.
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _onShopTap,
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_scene, _tap]),
                                builder: (context, _) => MerchantShopScene(
                                  time: _scene.value,
                                  tap: _tap.value,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeSlideIn(
                              animation: _question,
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
                    animation: _actions,
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
