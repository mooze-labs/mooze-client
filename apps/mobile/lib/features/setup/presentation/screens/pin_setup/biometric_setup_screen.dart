import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/setup/presentation/widgets/pin/biometric_hero.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

/// Shown immediately after initial PIN creation to let the user opt in to
/// biometric authentication.
///
/// This screen is only reached during the onboarding flow (not when changing
/// an existing PIN). If the user declines or if the biometric confirmation
/// fails, we fall through to the normal wallet-import loading screen.
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isLoading = false;

  Future<void> _enableBiometrics() async {
    setState(() => _isLoading = true);

    final t = AppLocalizations.of(context);
    final biometricService = ref.read(biometricServiceProvider);

    // Confirm a biometric works before persisting the preference. MUST be
    // biometric-only — otherwise a user could enable "biometric unlock" while
    // only proving they know the device PIN, leaving the preference flag in
    // an inconsistent state next session.
    final authResult = await biometricService
        .unlockWithBiometric(reason: t.biometric_auth_reason)
        .run();

    await authResult.fold(
      (error) async {
        if (mounted) {
          AppSnackBar.error(context, t.biometric_auth_error(error.message));
        }
      },
      (authenticated) async {
        if (!authenticated) {
          // User dismissed the prompt without authenticating — just skip.
          if (mounted) _proceed();
          return;
        }

        final saveResult = await biometricService.setEnabled(true).run();

        saveResult.fold(
          (error) {
            if (mounted) {
              AppSnackBar.error(context, t.biometric_save_error);
            }
          },
          (_) {
            if (mounted) {
              // Propagate the new preference to any listening provider.
              ref.invalidate(isBiometricEnabledProvider);
              _proceed();
            }
          },
        );
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  void _proceed() => context.go('/setup/wallet-import-loading');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PinScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Center(child: BiometricHero()),
          const SizedBox(height: 8),
          PinHeader(
            title: t.biometric_setup_enable_q,
            subtitle: t.biometric_setup_explanation,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          const SizedBox(height: 32),
          PrimaryButton(
            text: t.biometric_setup_enable,
            onPressed: _enableBiometrics,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 4),
          PinTextAction(
            label: t.common_no_thanks,
            onPressed: _isLoading ? null : _proceed,
          ),
        ],
      ),
    );
  }
}
