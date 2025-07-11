import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/mnemonic_input_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final mnemonicController = ref.watch(mnemonicControllerProvider);

    return ElevatedButton(
      onPressed: () async {
        final result =
            await mnemonicController.saveMnemonic(mnemonicInput).run();

        result.match(
          (failure) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure))),
          (success) => context.go("/setup/pin/new"),
        );
      },
      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
      child: Text(
        "Importar",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
