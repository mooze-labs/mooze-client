import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:no_screenshot/no_screenshot.dart';

import 'widgets.dart';

class DisplaySeedsScreen extends ConsumerWidget {
  DisplaySeedsScreen({super.key, required this.mnemonic});

  final String mnemonic;
  final NoScreenshot noScreenshot = NoScreenshot.instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mnemonic.isEmpty) {
      _redirectToConfigureSeeds(context);
      return _buildLoadingScaffold();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await noScreenshot.screenshotOn();
      },
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const TitleAndSubtitleCreateWallet(
                  title: 'Palavras de ',
                  highlighted: 'Recuperação',
                  subtitle:
                      'Anote estas palavras em um local seguro. Elas são a única forma de recuperar sua carteira.',
                ),
                const SizedBox(height: 24),
                Expanded(child: MnemonicGridDisplay(mnemonic: mnemonic)),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: "Confirmar frase",
                  onPressed: () => _goToConfirmSeeds(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _redirectToConfigureSeeds(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go("/setup/create-wallet/configure-seeds");
    });
  }

  void _goToConfirmSeeds(BuildContext context) {
    context.push("/setup/create-wallet/confirm-seeds", extra: mnemonic);
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("Frase de Recuperação"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text("Frase de Recuperação")),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
