import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/controllers/pix_tutorial_controller.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/callback_action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
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
  void _replayPixTutorial() {
    Future(() {
      if (!mounted) return;
      ref.read(pixTutorialControllerProvider.notifier).start();
      if (mounted) context.go('/home');
    });
  }

  /// Called when the user taps the biometric toggle. Enabling triggers the
  /// native prompt to confirm it works before persisting; disabling clears the
  /// preference immediately.
  Future<void> _handleBiometricToggle(bool enable) async {
    final biometricService = ref.read(biometricServiceProvider);
    final t = AppLocalizations.of(context);

    if (enable) {
      // Must be biometric-only — otherwise the user could enable the toggle
      // with their device PIN alone, leaving the verify-PIN flow unable to
      // satisfy the next biometric prompt.
      //
      // The auth-prompt flag stops the privacy shield from treating the native
      // dialog's `inactive` as a real backgrounding; `whenComplete` clears it
      // even if the prompt throws.
      final authPrompt = ref.read(authPromptActiveProvider.notifier);
      authPrompt.begin();
      final authResult = await biometricService
          .unlockWithBiometric(reason: t.biometric_auth_reason)
          .run()
          .whenComplete(authPrompt.end);

      if (!mounted) return;

      await authResult.fold(
        (error) async =>
            AppSnackBar.error(context, t.biometric_auth_error(error.message)),
        (authenticated) async {
          if (!authenticated) return;

          final saveResult = await biometricService.setEnabled(true).run();

          if (!mounted) return;

          saveResult.fold(
            (error) => AppSnackBar.error(context, t.biometric_save_error),
            (_) {
              ref.invalidate(isBiometricEnabledProvider);
              AppSnackBar.success(context, t.biometric_enabled_success);
            },
          );
        },
      );
    } else {
      final result = await biometricService.setEnabled(false).run();

      if (!mounted) return;

      result.fold(
        (error) => AppSnackBar.error(context, t.biometric_disable_error),
        (_) {
          ref.invalidate(isBiometricEnabledProvider);
          AppSnackBar.info(context, t.biometric_disabled_info);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isBiometricAvailable = ref.watch(isBiometricAvailableProvider);
    final isBiometricEnabled = ref.watch(isBiometricEnabledProvider);

    // Derived values with safe defaults while the futures resolve.
    final biometricAvailable = isBiometricAvailable.value ?? false;
    final biometricEnabled = isBiometricEnabled.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings_title),
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
              title: t.settings_section_security,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_view_recovery_phrase,
                  iconSvgPath: 'assets/icons/menu/settings/security_eye.svg',
                  action: Navigation(
                    context: context,
                    rota: '/setup/pin/verify',
                    verifyPinArgs: VerifyPinArgs(
                      onPinConfirmed: () async {
                        final seed = await ref.read(seedProvider.future);

                        seed.match(
                          (err) {
                            AppSnackBar.error(context, t.seed_fetch_error(err));
                          },
                          (maybeSeed) {
                            maybeSeed.match(
                              () {
                                AppSnackBar.warning(context, t.seed_not_found);
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
                  title: t.settings_change_pin,
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
                // necessary hardware.
                if (biometricAvailable)
                  ConfigStructure(
                    title: t.settings_biometric_auth,
                    iconSvgPath: 'assets/icons/menu/settings/biometrics.svg',
                    action: Toggle(
                      value: biometricEnabled,
                      onChange: _handleBiometricToggle,
                    ),
                  ),
                ConfigStructure(
                  title: t.settings_security,
                  iconSvgPath: 'assets/icons/menu/settings/security.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/security',
                  ),
                ),
                ConfigStructure(
                  title: t.settings_delete_wallet,
                  iconSvgPath: 'assets/icons/menu/settings/delete_account.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/delete-wallet',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_appearance,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_theme,
                  iconSvgPath: 'assets/icons/menu/settings/theme.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/theme-selector',
                  ),
                ),
                ConfigStructure(
                  title: t.settings_language,
                  iconSvgPath: 'assets/icons/menu/settings/language.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/language-selector',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_currency,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_change_currency,
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
              title: t.settings_section_account,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_referral_code,
                  iconSvgPath: 'assets/icons/menu/settings/gift.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/referral',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_legal,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_terms,
                  iconSvgPath: 'assets/icons/menu/settings/document.svg',
                  action: Navigation(context: context, rota: '/settings/terms'),
                ),
                ConfigStructure(
                  title: t.settings_license,
                  iconSvgPath: 'assets/icons/menu/settings/gavel.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/license',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_network,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_node_config,
                  iconSvgPath: 'assets/icons/menu/settings/nodes.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/node-config',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_addresses,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_verify_address,
                  iconSvgPath: 'assets/icons/menu/settings/verify.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/address-ownership',
                  ),
                ),
                ConfigStructure(
                  title: t.settings_address_explorer,
                  iconSvgPath: 'assets/icons/menu/settings/address.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/address-explorer',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_developer,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_logs,
                  iconSvgPath: 'assets/icons/menu/settings/data.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/developer-mode',
                  ),
                ),
              ],
            ),
            SectionSettings(
              title: t.settings_section_help,
              settingsItems: [
                ConfigStructure(
                  title: t.settings_contact_support,
                  iconSvgPath: 'assets/icons/menu/settings/support.svg',
                  action: Navigation(
                    context: context,
                    rota: '/settings/support',
                  ),
                ),
                ConfigStructure(
                  title: t.pix_tutorial_settings_replay,
                  iconSvgPath: 'assets/icons/menu/settings/tutorial.svg',
                  action: CallbackSettingsAction(_replayPixTutorial),
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
