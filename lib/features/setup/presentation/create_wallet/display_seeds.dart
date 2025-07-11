import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:no_screenshot/no_screenshot.dart';

import 'providers.dart';
import 'widgets.dart';

class DisplaySeedsScreen extends ConsumerWidget {
  final NoScreenshot noScreenshot = NoScreenshot.instance;

  DisplaySeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonic = ref.watch(
      generatedMnemonicProvider(ref.watch(extendedPhraseProvider)),
    );

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await noScreenshot.screenshotOn();
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Sua frase de recuperação")),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ATENÇÃO",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Anote estas palavras em ordem e guarde-as em local seguro.",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Essa é a única forma de recuperar sua carteira em caso de perda do dispositivo.",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              MnemonicGridDisplay(mnemonic: mnemonic),
              Spacer(),
              ElevatedButton(
                child: Text("Confirmar frase"),
                onPressed: () {
                  context.go(
                    "/create-wallet/confirm-mnemonic",
                    extra: mnemonic,
                  );
                },
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
