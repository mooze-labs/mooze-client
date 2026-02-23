import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';

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

        try {
          final existingMnemonicOption = await ref.read(
            mnemonicProvider.future,
          );
          final hasExistingWallet = existingMnemonicOption.isSome();

          if (hasExistingWallet) {
            ref.read(setWalletDeletionFlagProvider(true));

            try {
              await ref.read(disconnectBreezClientProvider.future);
            } catch (e) {}
            await Future.delayed(const Duration(milliseconds: 500));

            final secureStorage = SecureStorageProvider.instance;
            await secureStorage.delete(key: 'mnemonic');

            ref.invalidate(mnemonicProvider);

            await Future.delayed(const Duration(milliseconds: 300));

            ref.invalidate(liquidDataSourceProvider);
            ref.invalidate(bdkDatasourceProvider);
            ref.invalidate(breezClientProvider);

            await Future.delayed(const Duration(milliseconds: 1000));

            final walletManager = ref.read(walletDataManagerProvider.notifier);
            final cleanResult = await walletManager.cleanBreezDirectory();

            if (!cleanResult) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aviso: Alguns arquivos antigos não puderam ser removidos. O app pode precisar ser reiniciado.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }

            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (cleanupError) {
          ref.read(setWalletDeletionFlagProvider(false));
        }

        ref.read(setWalletDeletionFlagProvider(false));

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
            ref.invalidate(liquidDataSourceProvider);
            ref.invalidate(bdkDatasourceProvider);
            ref.invalidate(breezClientProvider);

            await Future.delayed(const Duration(milliseconds: 2000));

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
