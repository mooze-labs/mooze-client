import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/delete_wallet/delete_wallet_sign.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';

class DeleteWalletScreen extends StatefulWidget {
  const DeleteWalletScreen({super.key});

  @override
  State<DeleteWalletScreen> createState() => _DeleteWalletScreenState();
}

class _DeleteWalletScreenState extends State<DeleteWalletScreen> {
  bool _trustAware = false;
  bool _recoveryAware = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletar carteira'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Título principal
            const TitleAndSubtitleCreateWallet(
              title: 'Atenção ao deletar sua ',
              highlighted: 'carteira',
              subtitle:
                  'Ao deletar, será necessário passar novamente pelo sistema TRUST e você perderá acesso aos fundos se não tiver salvo sua frase de recuperação.',
            ),

            const SizedBox(height: 32),

            DeleteWalletSign(
              title: 'Limites PIX',
              description:
                  'Eu estou ciente de que precisarei passar novamente pelo sistema TRUST e que meus limites de PIX serão resetados.',
              isSelected: _trustAware,
              onTap: () {
                setState(() {
                  _trustAware = !_trustAware;
                });
              },
            ),
            const SizedBox(height: 16),
            DeleteWalletSign(
              title: 'Perda de fundos',
              description:
                  'Eu estou ciente que perderei acesso aos meus fundos caso não tenha guardado minha frase de recuperação.',
              isSelected: _recoveryAware,
              onTap: () {
                setState(() {
                  _recoveryAware = !_recoveryAware;
                });
              },
            ),

            const Spacer(),

            PrimaryButton(
              text: 'Deletar carteira',
              onPressed:
                  (_trustAware && _recoveryAware)
                      ? () => _verifyAndDeleteWallet(context)
                      : null,
              isEnabled: _trustAware && _recoveryAware,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _verifyAndDeleteWallet(BuildContext context) {
    final verifyPinArgs = VerifyPinArgs(
      onPinConfirmed: () async {
        final mnemonicHandler = MnemonicHandler();
        await mnemonicHandler.deleteMnemonic("mainWallet");
        if (context.mounted) {
          context.go('/setup/first-access');
        }
      },
      forceAuth: true,
    );
    context.push('/setup/pin/verify', extra: verifyPinArgs);
  }
}
