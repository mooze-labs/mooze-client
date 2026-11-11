import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Whether a hidden recovery phrase is shown.
///
/// The phrase hides again when the app leaves the foreground, so it is not
/// on screen when the user comes back.
class SeedRevealController extends ValueNotifier<bool> {
  SeedRevealController() : super(false) {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChange);
  }

  late final AppLifecycleListener _lifecycle;

  /// Counts the hides on leaving the foreground, which skip the fade.
  int get backgroundHides => _backgroundHides;
  int _backgroundHides = 0;

  void toggle() => value = !value;

  void _onLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || !value) return;
    _backgroundHides++;
    value = false;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}

/// Keeps a recovery phrase blurred until the user taps it, and blurs it
/// again on the next tap.
///
/// Hidden, it shows [placeholder] blurred under a reveal label. The phrase
/// is not built until then, so it is neither painted nor read by a screen
/// reader.
class SeedReveal extends StatelessWidget {
  const SeedReveal({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.child,
    this.blurPlaceholder = true,
  });

  final SeedRevealController controller;

  /// The layout of [child] with no secret in it.
  final Widget placeholder;

  final Widget child;

  /// False for a placeholder with its own frame, which blurs only what is
  /// inside it, so its edges stay sharp.
  final bool blurPlaceholder;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (context, revealed, _) => AnimatedSwitcher(
        // A hide on leaving the foreground starts a new switcher, which
        // drops the phrase at once instead of fading it out.
        key: ValueKey(controller.backgroundHides),
        duration: Motion.of(context, Motion.durationBase),
        switchInCurve: Motion.curveEnter,
        switchOutCurve: Motion.curveExit,
        child: revealed
            ? Semantics(
                key: const ValueKey(true),
                onTap: controller.toggle,
                onTapHint: t.seed_hide,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.toggle,
                  child: child,
                ),
              )
            : _HiddenSeed(
                key: const ValueKey(false),
                onReveal: controller.toggle,
                child: blurPlaceholder
                    ? SeedBlur(child: placeholder)
                    : placeholder,
              ),
      ),
    );
  }
}

/// The soft blur of a hidden phrase.
class SeedBlur extends StatelessWidget {
  const SeedBlur({super.key, required this.child});

  final Widget child;

  static const double _sigma = 5;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: _sigma,
        sigmaY: _sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }
}

class _HiddenSeed extends StatelessWidget {
  const _HiddenSeed({super.key, required this.onReveal, required this.child});

  final VoidCallback onReveal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).seed_reveal;
    final color = context.colors.textPrimary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onReveal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onReveal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            LiquidGlass(
              blurBackdrop: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, size: 18, color: color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
