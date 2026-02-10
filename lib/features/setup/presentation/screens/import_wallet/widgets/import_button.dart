import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../providers/seed_phrase_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';
import '../providers/import_loading_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);
    final mnemonicController = ref.watch(mnemonicControllerProvider);
    final isLoading = ref.watch(importLoadingProvider);
    final loadingNotifier = ref.read(importLoadingProvider.notifier);

    final validMnemonic =
        state.canComplete ? notifier.getValidMnemonic() : null;
    final isEnabled = !isLoading && validMnemonic != null;

    return PrimaryButton(
      text: "Importar Carteira",
      isLoading: isLoading,
      isEnabled: isEnabled,
      onPressed: () async {
        if (validMnemonic == null) return;

        loadingNotifier.state = true;
        notifier.setLoading(true);

        final result =
            await mnemonicController.saveMnemonic(validMnemonic).run();
        result.match(
          (failure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(child: Text(failure)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            loadingNotifier.state = false;
            notifier.setLoading(false);
          },
          (success) async {
            if (context.mounted) {
              context.push("/setup/pin/new");
            }
            loadingNotifier.state = false;
            notifier.setLoading(false);
          },
        );
      },
    );
  }
}
