import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/external_navigation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/section_settings_component.dart';

class MainSettingsScreen extends StatefulWidget {
  const MainSettingsScreen({super.key});

  @override
  State<MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<MainSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Ajustes')),
      body: Stack(
        children: [
          Column(
            children: [
              SectionSettings(
                title: 'COMERCIANTE',
                settingsItems: [
                  ConfigStructure(
                    title: 'Modo comerciante',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/merchant.svg',
                    action: Navigation(context: context, rota: '/menu'),
                    highlight: true,
                  ),
                ],
              ),
              SectionSettings(
                title: 'TRANSAÇÕES',
                settingsItems: [
                  ConfigStructure(
                    title: 'Histórico de transações',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/transaction.svg',
                    action: Navigation(context: context, rota: '/transactions'),
                  ),
                ],
              ),
              SectionSettings(
                title: 'CONFIGURAÇÕES',
                settingsItems: [
                  ConfigStructure(
                    title: 'Configurações',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/settings.svg',
                    action: Navigation(context: context, rota: '/settings'),
                  ),
                ],
              ),

              SectionSettings(
                title: 'LINKS EXTERNOS',
                settingsItems: [
                  ConfigStructure(
                    title: 'Saque de Depix',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/pix_out_line.svg',
                    action: ExternalNavigation(
                      rota: 'https://tally.so/r/w5EMVb',
                      context: context,
                    ),
                  ),
                  ConfigStructure(
                    title: 'Central de dados',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/data.svg',
                    action: ExternalNavigation(
                      rota: 'https://keepo.io/mooze.app/',
                      context: context,
                    ),
                  ),
                  ConfigStructure(
                    title: 'GitHub',
                    iconSvgPath:
                        'assets/new_ui_wallet/assets/icons/menu/settings/github.svg',
                    action: ExternalNavigation(
                      rota: 'https://github.com/mooze-labs',
                      context: context,
                    ),
                  ),
                ],
              ),
              SectionSettings(
                title: 'VERSÃO',
                settingsItems: [
                  ConfigStructure(title: '2025.08.11(1)'),
                ], // TODO: ADD version
              ),
            ],
          ),
        ],
      ),
    );
  }
}