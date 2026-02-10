import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/section_settings_component.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';

final seedProvider = FutureProvider<Either<String, Option<String>>>((
  ref,
) async {
  final MnemonicStore mnemonicStore = ref.read(mnemonicStoreProvider);
  return mnemonicStore.getMnemonic().run();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
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
                        // Consome o provider
                        final seed = await ref.read(seedProvider.future);

                        seed.match(
                          // erro
                          (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: $err')),
                            );
                          },
                          (maybeSeed) {
                            maybeSeed.match(
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nenhuma seed encontrada.'),
                                  ),
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
