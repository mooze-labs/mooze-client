import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../providers/mnemonic_input_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';
import '../providers/import_loading_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final mnemonicController = ref.watch(mnemonicControllerProvider);
    final isLoading = ref.watch(importLoadingProvider);
    final loadingNotifier = ref.read(importLoadingProvider.notifier);
    return PrimaryButton(
      text: "Importar",
      isLoading: isLoading,
      isEnabled: !isLoading && mnemonicInput.isNotEmpty,
      onPressed: () async {
        loadingNotifier.state = true;
        final result =
            await mnemonicController.saveMnemonic(mnemonicInput).run();
        result.match(
          (failure) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure))),
          (success) async {
            if (context.mounted) {
              context.push("/setup/pin/new");
            }
          },
        );
        loadingNotifier.state = false;
      },
    );
  }
}
