import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:no_screenshot/no_screenshot.dart';

import 'widgets.dart';

class DisplaySeedsScreen extends ConsumerWidget {
  final NoScreenshot noScreenshot = NoScreenshot.instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonic = GoRouterState.of(context).extra as String?;

    // If no mnemonic is provided, redirect to configure seeds
    if (mnemonic == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go("/setup/create-wallet/configure-seeds");
      });
      return Scaffold(
        appBar: AppBar(title: Text("Sua frase de recuperação")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await noScreenshot.screenshotOn();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sua frase de recuperação"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go("/setup/create-wallet/configure-seeds"),
          ),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    "/setup/create-wallet/confirm-seeds",
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
