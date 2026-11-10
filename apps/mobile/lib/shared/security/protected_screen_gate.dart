import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'screen_security_controller.dart';

/// Shows a notice before a screen with sensitive wallet data, such as the
/// recovery phrase, and shows the screen once the user acknowledges it.
///
/// The notice sits on the screen backdrop: the logo, a glass emblem with a
/// shield and a crossed-out camera, the title and the message, and the
/// warning in a glass panel. The acknowledge button is pinned at the bottom
/// and is the only brand color of the screen. The content fades and rises
/// in, section by section, unless reduced motion is on.
class ProtectedScreenGate extends StatefulWidget {
  const ProtectedScreenGate({super.key, required this.child, this.logo});

  final Widget child;

  final Widget? logo;

  @override
  State<ProtectedScreenGate> createState() => _ProtectedScreenGateState();
}

class _ProtectedScreenGateState extends State<ProtectedScreenGate>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;

  /// Sections of the notice that enter one after the other.
  static const int _sections = 4;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Motion.staggeredEntrance(_sections),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_entrance.isDismissed) return;
    if (Motion.isReduced(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  void _reveal() {
    ScreenSecurityController.instance.enable();
    setState(() => _revealed = true);
  }

  @override
  void dispose() {
    if (_revealed) ScreenSecurityController.instance.disable();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) return widget.child;

    final t = AppLocalizations.of(context);
    Widget section(int index, Widget child) => FadeSlideIn(
      animation: staggeredAnimation(_entrance, index),
      child: child,
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child:
                      widget.logo ??
                      SvgPicture.asset(
                        'assets/logos/logo_primary.svg',
                        width: 96,
                        colorFilter: ColorFilter.mode(
                          context.colors.logoColor,
                          BlendMode.srcIn,
                        ),
                      ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          section(0, const _Emblem()),
                          const SizedBox(height: 32),
                          section(
                            1,
                            Column(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    t.screenshot_blocked_title,
                                    textAlign: TextAlign.center,
                                    style: context.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t.screenshot_blocked_message,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyLarge?.copyWith(
                                    color: context.colors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          section(
                            2,
                            _WarningPanel(t.screenshot_blocked_warning),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: section(
                    3,
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: t.screenshot_blocked_acknowledge,
                        onPressed: _reveal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A glass disc with a shield, a faint ring around it, and a small glass
/// badge with a crossed-out camera: the screen is protected from capture.
class _Emblem extends StatelessWidget {
  const _Emblem();

  static const double _ring = 152;
  static const double _disc = 112;
  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    final hairline = AppSurfaces.hairline(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: hairline),
              ),
            ),
            SizedBox.square(
              dimension: _disc,
              child: LiquidGlass(
                blurBackdrop: false,
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 48,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
            // The badge sits on the lower right edge of the disc.
            Positioned(
              right: (_ring - _disc) / 2 - 2,
              bottom: (_ring - _disc) / 2 - 2,
              child: SizedBox.square(
                dimension: _badge,
                child: LiquidGlass(
                  blurBackdrop: false,
                  opaque: true,
                  child: Center(
                    child: Icon(
                      Icons.no_photography_outlined,
                      size: 20,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The warning about screenshots of the recovery phrase, in a glass panel.
/// The warning color stays on the icon, so the text keeps its contrast.
class _WarningPanel extends StatelessWidget {
  const _WarningPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: context.appColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
