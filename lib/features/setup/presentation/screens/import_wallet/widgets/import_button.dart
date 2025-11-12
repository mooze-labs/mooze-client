import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

import '../providers/mnemonic_input_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final mnemonicController = ref.watch(mnemonicControllerProvider);
    return PrimaryButton(
      text: "Importar",
      onPressed: () async {
        final result =
            await mnemonicController.saveMnemonic(mnemonicInput).run();
        result.match(
          (failure) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure))),
          (success) async {
            final walletDataManager = ref.read(
              walletDataManagerProvider.notifier,
            );
            walletDataManager.invalidateAllWalletProviders();

            await walletDataManager.initializeWallet();

            if (context.mounted) {
              context.push("/setup/pin/new");
            }
          },
        );
      },
    );
  }
}
