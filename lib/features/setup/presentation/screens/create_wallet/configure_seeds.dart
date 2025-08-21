import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/generate_seeds_button.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/phrase_length_selection.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';

class ConfigureSeedsScreen extends StatelessWidget {
  const ConfigureSeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Criar carteira'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            TitleAndSubtitleCreateWallet(
              title: 'Selecione o tamanho da ',
              highlighted: 'frase-semente',
              subtitle:
                  'Você pode criar sua carteira com 12 ou 24 palavras. Ambas são seguras, mas cada opção tem seu nível de praticidade e proteção.',
            ),

            SizedBox(height: 32),

            SeedPhraseSelector(),

            Spacer(),

            GenerateSeedsButton(),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
