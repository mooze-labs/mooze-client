import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/section_settings.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';

final seedProvider = FutureProvider<Either<String, Option<String>>>((
  ref,
) async {
  final MnemonicStore mnemonicStore = ref.watch(mnemonicStoreProvider);
  return mnemonicStore.getMnemonic().run();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Called when the user taps the biometric toggle.
  ///
  /// Enabling: triggers the native prompt to confirm it actually works before
  /// persisting the preference.
  /// Disabling: clears the preference immediately.
  Future<void> _handleBiometricToggle(bool enable) async {
    final biometricService = ref.read(biometricServiceProvider);

    if (enable) {
      final authResult = await biometricService
          .authenticate(
            reason:
                'Confirme sua identidade para ativar a autenticação biométrica',
          )
          .run();

      if (!mounted) return;

      await authResult.fold(
        (error) async => AppSnackBar.error(context, 'Erro ao autenticar: $error'),
        (authenticated) async {
          if (!authenticated) return; // user dismissed — leave toggle off

          final saveResult = await biometricService.setEnabled(true).run();

          if (!mounted) return;

          saveResult.fold(
            (error) => AppSnackBar.error(context, 'Erro ao salvar configuração.'),
            (_) {
              ref.invalidate(isBiometricEnabledProvider);
              AppSnackBar.success(context, 'Autenticação biométrica ativada.');
            },
          );
        },
      );
    } else {
      final result = await biometricService.setEnabled(false).run();

      if (!mounted) return;

      result.fold(
        (error) => AppSnackBar.error(context, 'Erro ao desativar biometria.'),
        (_) {
          ref.invalidate(isBiometricEnabledProvider);
          AppSnackBar.info(context, 'Autenticação biométrica desativada.');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBiometricAvailable = ref.watch(isBiometricAvailableProvider);
    final isBiometricEnabled = ref.watch(isBiometricEnabledProvider);

    // Derived values with safe defaults while the futures resolve.
    final biometricAvailable = isBiometricAvailable.value ?? false;
    final biometricEnabled = isBiometricEnabled.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SectionSettings(
              title: 'SEGURANÇA',
              settingsItems: [
                ConfigStructure(
                  title: 'Ver frase de recuperação',
                  iconSvgPath: 'assets/icons/menu/settings/security.svg',
                  action: Navigation(
                    context: context,
                    rota: '/setup/pin/verify',
                    verifyPinArgs: VerifyPinArgs(
                      onPinConfirmed: () async {
                        final seed = await ref.read(seedProvider.future);

                        seed.match(
                          (err) {
                            AppSnackBar.error(context, 'Erro: $err');
                          },
                          (maybeSeed) {
                            maybeSeed.match(
                              () {
                                AppSnackBar.warning(
                                  context,
                                  'Nenhuma seed encontrada.',
                                );
                              },
                              (seedValue) {
                                context.pushReplacement(
                                  '/settings/view-mnemonic',
                                  extra: seedValue,
                                );
                              },
                            );
                          },
                        );
                      },
                      forceAuth: true,
                    ),
                  ),
                ),
                ConfigStructure(
                  title: 'Mudar PIN',
                  iconSvgPath: 'assets/icons/menu/settings/key.svg',
                  action: Navigation(
                    context: context,
                    rota: '/setup/pin/verify',
                    verifyPinArgs: VerifyPinArgs(
                      onPinConfirmed: () {
                        context.push('/setup/pin/new', extra: true);
                      },
                      forceAuth: true,
                    ),
                  ),
                ),
                // Only surface the biometric toggle when the device has the
                // necessary hardware — no point showing it on unsupported
                // devices.
                if (biometricAvailable)
                  ConfigStructure(
                    title: 'Autenticação biométrica',
                    iconSvgPath: 'assets/icons/menu/settings/security.svg',
                    action: Toggle(
                      value: biometricEnabled,
                      onChange: _handleBiometricToggle,
                    ),
                  ),
                ConfigStructure(
                  title: 'Deletar carteira',
                  iconSvgPath: 'assets/icons/menu/settings/delete_account.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/delete-wallet',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'APARÊNCIA',
              settingsItems: [
                ConfigStructure(
                  title: 'Tema',
                  iconSvgPath: 'assets/icons/menu/settings/theme.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/theme-selector',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'MOEDA',
              settingsItems: [
                ConfigStructure(
                  title: 'Alterar Moeda',
                  iconSvgPath:
                      'assets/icons/menu/settings/currency_exchange.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/currency-selector',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'CONTA E BENEFICIOS',
              settingsItems: [
                ConfigStructure(
                  title: 'Cupom de Indicação',
                  iconSvgPath: 'assets/icons/menu/settings/gift.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/referral',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'LEGAL',
              settingsItems: [
                ConfigStructure(
                  title: 'Termos de uso',
                  iconSvgPath: 'assets/icons/menu/settings/document.svg',
                  action: Navigation(context: context, rota: '/settings/terms'),
                ),
                ConfigStructure(
                  title: 'Licença GPL',
                  iconSvgPath: 'assets/icons/menu/settings/gavel.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/license',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'DESENVOLVEDOR',
              settingsItems: [
                ConfigStructure(
                  title: 'Logs',
                  iconSvgPath: 'assets/icons/menu/settings/data.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/developer-mode',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: 'AJUDA',
              settingsItems: [
                ConfigStructure(
                  title: 'Contatar suporte',
                  iconSvgPath: 'assets/icons/menu/settings/support.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/support',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
