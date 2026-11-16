import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_seal.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'lock_vault.dart';

/// The branded, fully opaque privacy / lock face.
///
/// Two roles with the same look so transitions are seamless: a cosmetic shield
/// (no callbacks) covering the app switcher and lifecycle transitions, and an
/// active lock face (callbacks supplied) that auto-prompts biometrics with a
/// "Use PIN" fallback. Being the same widget in both roles avoids a visual swap
/// — and therefore a content flash — on resume.
///
/// When the user unlocks with a biometric, its art is the biometric seal
/// ([sealKind]): at rest on the cosmetic shield, driven by [seal] on the lock
/// face, where it scans while the system prompt is up. Otherwise it is the
/// vault of the onboarding, at rest ([LockVault]), in the same place. The room of the actions is kept in both roles, so the art and
/// the texts stay in place when the actions fade in.
///
/// It sits on the backdrop of the screens of the app ([AppBackdrop]), the
/// same as the PIN screen that opens over it, on an opaque surface: the
/// cover hides the wallet whatever the backdrop paints.
class PrivacyShieldOverlay extends StatelessWidget {
  /// When non-null, shows a "Use PIN" button that switches to PIN entry.
  final VoidCallback? onUsePin;

  /// When non-null, shows a "Use biometrics" button that (re)triggers the
  /// biometric prompt.
  final VoidCallback? onUseBiometric;

  /// Whether a biometric prompt is currently in flight.
  final bool isBiometricLoading;

  /// The biometric on the seal, when the user unlocks with one. Without it,
  /// the art is the vault ([LockVault]).
  final BiometricKind? sealKind;

  /// Drives the seal on the lock face. Without it, the seal rests.
  final BiometricSeal? seal;

  const PrivacyShieldOverlay({
    super.key,
    this.onUsePin,
    this.onUseBiometric,
    this.isBiometricLoading = false,
    this.sealKind,
    this.seal,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final kind = sealKind;
    final seal = this.seal;

    // The floor of the stage reaches its bottom: the logo keeps clear of it.
    final art = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch ((kind, seal)) {
        (null, _) => const LockVault(),
        (final kind?, null) => BiometricScene(
          kind: kind,
          motion: const BiometricMotion(),
          finale: BiometricFinale.check,
        ),
        (final kind?, final seal?) => BiometricSealView(seal: seal, kind: kind),
      },
    );

    return SizedBox.expand(
      child: Material(
        color: colorScheme.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        // The shockwave of the seal crosses the whole cover.
                        child: SingleChildScrollView(
                          clipBehavior: Clip.none,
                          child: Column(
                            children: [
                              art,
                              SvgPicture.asset(
                                'assets/logos/logo_primary.svg',
                                width: 160,
                                colorFilter: ColorFilter.mode(
                                  context.colors.logoColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                t.privacy_shield_locked_title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.privacy_shield_locked_subtitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Active lock face: biometric + PIN affordances. Hidden on
                    // the cosmetic app-switcher cover, and while the seal
                    // confirms an unlock.
                    _Action(
                      shown: onUseBiometric != null,
                      child: PrimaryButton(
                        text: t.pin_use_biometric,
                        onPressed: onUseBiometric,
                        isEnabled: !isBiometricLoading,
                        isLoading: isBiometricLoading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Action(
                      shown: onUsePin != null,
                      child: TextButton(
                        onPressed: onUsePin,
                        child: Text(
                          t.pin_use_pin,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
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

/// An action of the lock face, which keeps its room while hidden: it fades,
/// takes no taps, and is hidden from screen readers.
class _Action extends StatelessWidget {
  const _Action({required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: shown ? 1 : 0,
    duration: Motion.of(context, Motion.durationBase),
    curve: shown ? Motion.curveEnter : Motion.curveExit,
    child: IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(excluding: !shown, child: child),
    ),
  );
}
