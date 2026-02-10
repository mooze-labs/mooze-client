import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/external_navigation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/section_settings_component.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainSettingsScreen extends StatefulWidget {
  const MainSettingsScreen({super.key});

  @override
  State<MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<MainSettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v.${packageInfo.version}(${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SectionSettings(
                  title: 'COMERCIANTE',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Modo comerciante',
                      iconSvgPath: 'assets/icons/menu/settings/merchant.svg',
                      action: Navigation(
                        context: context,
                        rota: '/merchant',
                        args: '/menu',
                      ),
                      highlight: true,
                    ),
                  ],
                ),
                SectionSettings(
                  title: 'TRANSAÇÕES',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Histórico de transações',
                      iconSvgPath: 'assets/icons/menu/settings/transaction.svg',
                      action: Navigation(
                        context: context,
                        rota: '/transactions-history',
                      ),
                    ),
                  ],
                ),
                SectionSettings(
                  title: 'CONFIGURAÇÕES',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Configurações',
                      iconSvgPath: 'assets/icons/menu/settings/settings.svg',
                      action: Navigation(context: context, rota: '/settings'),
                    ),
                  ],
                ),
                SectionSettings(
                  title: 'CARTEIRA',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Nivel da carteira',
                      iconSvgPath:
                          'assets/icons/menu/settings/wallet_level.svg',
                      action: Navigation(
                        context: context,
                        rota: '/wallet-levels',
                      ),
                    ),
                    // TODO: Add this back when the feature is ready
                    // ConfigStructure(
                    //   title: 'Verificação de Humanidade',
                    //   iconSvgPath: 'assets/icons/menu/settings/data.svg',
                    //   action: Navigation(
                    //     context: context,
                    //     rota: '/human-verification',
                    //   ),
                    // ),
                  ],
                ),
                SectionSettings(
                  title: 'LINKS EXTERNOS',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Serviços via Bitcoin',
                      iconSvgPath:
                          'assets/icons/menu/settings/pix_out_line.svg',
                      action: ExternalNavigation(
                        rota: 'https://pagbitcoin.com/?ref=0099',
                        context: context,
                      ),
                    ),
                    ConfigStructure(
                      title: 'Suporte',
                      iconSvgPath: 'assets/icons/menu/settings/data.svg',
                      action: ExternalNavigation(
                        rota: 'https://keepo.io/mooze.app/',
                        context: context,
                      ),
                    ),
                    ConfigStructure(
                      title: 'GitHub',
                      iconSvgPath: 'assets/icons/menu/settings/github.svg',
                      action: ExternalNavigation(
                        rota: 'https://github.com/mooze-labs',
                        context: context,
                      ),
                    ),
                  ],
                ),
                SectionSettings(
                  title: 'TAXAS',
                  settingsItems: [
                    ConfigStructure(
                      title: 'Taxas do PIX',
                      iconSvgPath: 'assets/icons/menu/settings/fee.svg',
                      action: Navigation(context: context, rota: '/pix/fees'),
                    ),
                  ],
                ),
                SectionSettings(
                  title: 'VERSÃO',
                  settingsItems: [
                    ConfigStructure(
                      title:
                          _appVersion.isEmpty ? 'Carregando...' : _appVersion,
                    ),
                  ],
                ),
                SizedBox(height: 140),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
