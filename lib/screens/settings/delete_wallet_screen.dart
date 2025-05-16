import 'package:flutter/material.dart';
import 'package:mooze_mobile/screens/first_access/first_access.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

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
      appBar: MoozeAppBar(title: "Deletar carteira"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Atenção: ao clicar no botão abaixo, você apagará a carteira do armazenamento do seu dispositivo. Você terá que passar novamente pelo sistema TRUST para atingir maiores limites de PIX. Você também perderá acesso aos seus fundos caso não tenha feito backup da sua frase de recuperação.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _trustAware,
              onChanged: (value) {
                setState(() {
                  _trustAware = value ?? false;
                });
              },
              title: const Text(
                "Eu estou ciente de que precisarei passar novamente pelo sistema TRUST e que meus limites de PIX serão resetados.",
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _recoveryAware,
              onChanged: (value) {
                setState(() {
                  _recoveryAware = value ?? false;
                });
              },
              title: const Text(
                "Eu estou ciente que perderei acesso aos meus fundos caso não tenha guardado minha frase de recuperação",
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  (_trustAware && _recoveryAware)
                      ? () => _verifyAndDeleteWallet(context)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text(
                "Deletar carteira",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _verifyAndDeleteWallet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VerifyPinScreen(
              onPinConfirmed: () async {
                final mnemonicHandler = MnemonicHandler();
                await mnemonicHandler.deleteMnemonic("mainWallet");
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const FirstAccessScreen(),
                    ),
                  );
                }
              },
              forceAuth: true,
            ),
      ),
    );
  }
}
