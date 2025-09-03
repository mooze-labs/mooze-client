import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/mnemonic_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import 'package:no_screenshot/no_screenshot.dart';
import '../providers/extended_phrase_provider.dart';

class GenerateSeedsButton extends ConsumerWidget {
  const GenerateSeedsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryButton(
      text: 'Gerar frase de recuperação',
      onPressed: () async {
        await deactivateScreenshot().run();

        if (context.mounted) {
          final extendedPhrase = ref.read(extendedPhraseProvider);
          final mnemonic = ref
              .read(mnemonicControllerProvider)
              .generateMnemonic(extendedPhrase);

          context.push("/setup/create-wallet/display-seeds", extra: mnemonic);
        }
      },
    );
  }
}

Task<bool> deactivateScreenshot() {
  final noScreenshot = NoScreenshot.instance;
  return Task(() => noScreenshot.screenshotOff());
}
