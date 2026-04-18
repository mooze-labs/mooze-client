import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    final biometricService = ref.read(biometricServiceProvider);

    // Confirm the biometric works before persisting the preference — avoids
    // enabling a feature that the hardware cannot actually satisfy.
    final authResult = await biometricService
        .authenticate(
          reason:
              'Confirme sua identidade para ativar a autenticação biométrica',
        )
        .run();

    await authResult.fold(
      (error) async {
        if (mounted) {
          AppSnackBar.error(context, 'Erro ao autenticar: $error');
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
              AppSnackBar.error(context, 'Erro ao salvar configuração.');
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
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    const TextSpan(text: 'Ativar '),
                    TextSpan(
                      text: 'biometria',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use Face ID, impressão digital ou a senha do dispositivo '
                'para acessar sua carteira com mais rapidez e segurança.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: 'Ativar biometria',
                onPressed: _enableBiometrics,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Não, obrigado',
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
