import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The branded, fully opaque privacy / lock face.
///
/// Two roles with the same look so transitions are seamless: a cosmetic shield
/// (no callbacks) covering the app switcher and lifecycle transitions, and an
/// active lock face (callbacks supplied) that auto-prompts biometrics with a
/// "Use PIN" fallback. Being the same widget in both roles avoids a visual swap
/// — and therefore a content flash — on resume.
class PrivacyShieldOverlay extends StatelessWidget {
  /// When non-null, shows a "Use PIN" button that switches to PIN entry.
  final VoidCallback? onUsePin;

  /// When non-null, shows a "Use biometrics" button that (re)triggers the
  /// biometric prompt.
  final VoidCallback? onUseBiometric;

  /// Whether a biometric prompt is currently in flight.
  final bool isBiometricLoading;

  const PrivacyShieldOverlay({
    super.key,
    this.onUsePin,
    this.onUseBiometric,
    this.isBiometricLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.expand(
      child: Material(
        color: colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.privacy_shield_locked_subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),

                // Active lock face: biometric + PIN affordances. Absent for the
                // cosmetic app-switcher cover.
                if (onUseBiometric != null || onUsePin != null) ...[
                  const SizedBox(height: 40),
                  if (onUseBiometric != null)
                    PrimaryButton(
                      text: t.pin_use_biometric,
                      onPressed: onUseBiometric,
                      isEnabled: !isBiometricLoading,
                      isLoading: isBiometricLoading,
                    ),
                  if (onUsePin != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onUsePin,
                      child: Text(
                        t.pin_use_pin,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
