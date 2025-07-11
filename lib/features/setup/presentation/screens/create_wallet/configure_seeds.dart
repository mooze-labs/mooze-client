import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class ConfigureSeedsScreen extends ConsumerWidget {
  const ConfigureSeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gerar frase de recuperação"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go("/setup/first-access"),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                Text(
                  "Selecione o tamanho da frase de recuperação",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                PhraseLengthSelection(),
                Spacer(),
                GenerateSeedsButton(),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
