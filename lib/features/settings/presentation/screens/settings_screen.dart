import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/section_settings_component.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.go('/menu');
          },
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              SectionSettings(
                title: 'SEGURANÇA',
                settingsItems: [
                  ConfigStructure(
                    title: 'Ver frase de recuperação',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/security.svg',
                    action: Navigation(
                      context: context,
                      rota: '/settings/view-mnemonic',
                    ),
                  ),
                  ConfigStructure(
                    title: 'Mudar PIN',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/key.svg',
                    action: Navigation(
                      context: context,
                      rota: '/setup/pin/verify', // TODO: Implement to call the /setup/pin/new screen when the verification returns true
                    ),
                  ),
                  ConfigStructure(
                    title: 'Deletar carteira',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/delete_account.svg',
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
                        'assets/new_ui_wallet/assets/icons/menu/settings/currency_exchange.svg',
                    action: Navigation(
                      context: context,
                      rota: '/settings/theme/',
                    ),
                  ),
                ],
              ),
              SectionSettings(
                title: 'CONTA E BENEFICIOS',
                settingsItems: [
                  ConfigStructure(
                    title: 'Cupom de Indicação',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/gift.svg',
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
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/document.svg',
                    action: Navigation(
                      context: context,
                      rota: '/settings/terms',
                    ),
                  ),
                  ConfigStructure(
                    title: 'Licença GPL',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/gavel.svg',
                    action: Navigation(
                      context: context,
                      rota: '/settings/license',
                    ),
                  ),
                ],
              ),
              SectionSettings(
                title: 'AJUDA',
                settingsItems: [
                  ConfigStructure(
                    title: 'Contatar suporte',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/support.svg',
                    action: Navigation(
                      context: context,
                      rota: '/settings/support',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
