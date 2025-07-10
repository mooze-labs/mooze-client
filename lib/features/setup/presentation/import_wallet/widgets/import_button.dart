import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/shared/providers/mnemonic_controller_provider.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final mnemonicController = ref.watch(mnemonicControllerProvider);

    return ElevatedButton(
      child: Text("Importar"),
      onPressed: () async {
        final result =
            await mnemonicController.saveMnemonic(mnemonicInput).run();

        result.match(
          (failure) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure))),
          (success) => context.go("/home"),
        );
      },
    );
  }
}
