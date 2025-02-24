import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/mnemonic_provider.dart';

class CreateNewWalletScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicState = ref.watch(mnemonicNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Criar nova carteira"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          StarryBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sua frase de recuperação:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  mnemonicState.when(
                    loading: () => CircularProgressIndicator(),
                    error:
                        (err, _) => Text(
                          "Erro: $err",
                          style: TextStyle(color: Colors.red),
                        ),
                    data: (mnemonic) {
                      if (mnemonic == null) {
                        return ElevatedButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(mnemonicNotifierProvider.notifier)
                                      .generateMnemonic(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD973C1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 40,
                            ),
                          ),
                          child: Text(
                            "Gerar Nova Frase",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final words = mnemonic.split(" ");

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  6,
                                  (index) => _buildMnemonicWord(words, index),
                                ),
                              ),
                              SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  6,
                                  (index) =>
                                      _buildMnemonicWord(words, index + 6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/confirm-mnemonic');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD973C1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 40,
                              ),
                            ),
                            child: Text(
                              "Confirmar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicWord(List<String> words, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        "${index + 1}. ${words[index]}",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}

class StarryBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.black));
  }
}
