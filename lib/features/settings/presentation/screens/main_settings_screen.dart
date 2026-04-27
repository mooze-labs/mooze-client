import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/external_navigation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/section_settings.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.main_settings_title),
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
                  title: t.main_settings_section_merchant,
                  settingsItems: [
                    ConfigStructure(
                      title: t.merchant_mode_header,
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
                  title: t.main_settings_section_transactions,
                  settingsItems: [
                    ConfigStructure(
                      title: t.tx_history_title,
                      iconSvgPath: 'assets/icons/menu/settings/transaction.svg',
                      action: Navigation(
                        context: context,
                        rota: '/transactions-history',
                      ),
                    ),
                  ],
                ),
                SectionSettings(
                  title: t.main_settings_section_settings,
                  settingsItems: [
                    ConfigStructure(
                      title: t.main_settings_settings_label,
                      iconSvgPath: 'assets/icons/menu/settings/settings.svg',
                      action: Navigation(context: context, rota: '/settings'),
                    ),
                  ],
                ),
                SectionSettings(
                  title: t.main_settings_section_wallet,
                  settingsItems: [
                    ConfigStructure(
                      title: t.main_settings_wallet_level,
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
                  title: t.main_settings_section_external_links,
                  settingsItems: [
                    ConfigStructure(
                      title: t.main_settings_btc_services,
                      iconSvgPath:
                          'assets/icons/menu/settings/pix_out_line.svg',
                      action: ExternalNavigation(
                        rota: 'https://pagbitcoin.com/?ref=0099',
                        context: context,
                      ),
                    ),
                    ConfigStructure(
                      title: t.main_settings_support,
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
                  title: t.main_settings_section_fees,
                  settingsItems: [
                    ConfigStructure(
                      title: t.main_settings_pix_fees,
                      iconSvgPath: 'assets/icons/menu/settings/fee.svg',
                      action: Navigation(context: context, rota: '/pix/fees'),
                    ),
                  ],
                ),
                SectionSettings(
                  title: t.main_settings_section_version,
                  settingsItems: [
                    ConfigStructure(
                      title:
                          _appVersion.isEmpty ? t.common_loading : _appVersion,
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
