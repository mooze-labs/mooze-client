import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/screens/pin/create_pin.dart';
import 'package:mooze_mobile/screens/settings/view_mnemonic.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Configurações"),
      drawer: MoozeDrawer(),
      body: ListView(
        children: [
          _buildSettingsItem(
            context,
            "Ver frase de recuperação",
            Icons.vpn_key,
            () => _showRecoveryPhrase(context),
          ),
          _buildSettingsItem(
            context,
            "Mudar PIN",
            Icons.lock,
            () => _changePin(context),
          ),
          _buildSettingsItem(
            context,
            "Termos de uso",
            Icons.description,
            () => Navigator.pushNamed(context, "/terms-and-conditions"),
          ),
          _buildSettingsItem(
            context,
            "Contatar suporte",
            Icons.support_agent,
            () => _contactSupport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    Function() onTap,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showRecoveryPhrase(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VerifyPinScreen(
              onPinConfirmed: () async {
                // Retrieve the mnemonic and show it
                final mnemonicHandler = MnemonicHandler();
                final mnemonic = await mnemonicHandler.retrieveWalletMnemonic(
                  "mainWallet",
                );

                if (mnemonic != null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ViewMnemonicScreen(mnemonic: mnemonic),
                    ),
                  );
                }
              },
            ),
      ),
    );
  }

  void _changePin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VerifyPinScreen(
              onPinConfirmed: () {
                // After verifying current PIN, redirect to the PIN creation screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePinScreen()),
                );
              },
            ),
      ),
    );
  }

  void _contactSupport(BuildContext context) async {
    final Uri url = Uri.parse("https://t.me/Moozep2pbot");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Não foi possível abrir o Telegram")),
        );
      }
    }
  }
}
