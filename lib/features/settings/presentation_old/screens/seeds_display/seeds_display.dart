import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'widgets.dart';

class SeedsDisplayScreen extends ConsumerWidget {
  const SeedsDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seeds Display'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: seed.when(
        data:
            (data) => data.fold(
              (error) => Center(
                child: Text(
                  "Não foi possível recuperar sua frase de recuperação: $error",
                ),
              ),
              (optionSeed) => optionSeed.fold(
                () => const Center(
                  child: Text("Frase de recuperação não definida."),
                ),
                (seed) => Column(
                  children: [
                    MnemonicGridDisplay(mnemonic: seed),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: seed));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Frase copiada para a área de transferência",
                            ),
                          ),
                        );
                      },
                      child: const Text("Copiar frase de recuperação"),
                    ),
                  ],
                ),
              ),
            ),
        error:
            (error, stackTrace) => Center(
              child: Text("Erro ao carregar a frase de recuperação: $error"),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
