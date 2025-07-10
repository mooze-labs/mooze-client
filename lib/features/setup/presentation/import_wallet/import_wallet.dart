import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets.dart';

class ImportWalletScreen extends ConsumerWidget {
  const ImportWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text("Importar carteira")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Digite suas palavras de recuperação separadas por espaço.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            MnemonicInputField(),
            SizedBox(height: 20),
            ImportButton(),
          ],
        ),
      ),
    );
  }
}
