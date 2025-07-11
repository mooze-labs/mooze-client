import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:no_screenshot/no_screenshot.dart';

class GenerateSeedsButton extends ConsumerWidget {
  const GenerateSeedsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      label: Text("Gerar frase de recuperação"),
      onPressed: () async {
        await deactivateScreenshot().run();

        if (context.mounted) {
          context.go("/create-wallet/display-seeds");
        }
      },
    );
  }
}

Task<bool> deactivateScreenshot() {
  final noScreenshot = NoScreenshot.instance;
  return Task(() => noScreenshot.screenshotOff());
}
