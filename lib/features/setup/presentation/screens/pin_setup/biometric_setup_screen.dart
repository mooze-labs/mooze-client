import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 80, color: colorScheme.primary),
              const SizedBox(height: 32),
              Text(
                t.biometric_setup_enable_q,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.biometric_setup_explanation,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: t.biometric_setup_enable,
                onPressed: _enableBiometrics,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: t.common_no_thanks,
                onPressed: _proceed,
                isEnabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
