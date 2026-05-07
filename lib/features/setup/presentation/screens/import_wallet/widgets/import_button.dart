import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/wallet/domain/usecases/clean_working_dirs.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../providers/seed_phrase_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';
import '../providers/import_loading_provider.dart';


class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  static const List<String> _walletWorkingDirs = ['lwk-db', 'breez'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);
    final mnemonicController = ref.watch(mnemonicControllerProvider);
    final isLoading = ref.watch(importLoadingProvider);
    final loadingNotifier = ref.read(importLoadingProvider.notifier);

    final validMnemonic =
        state.canComplete ? notifier.getValidMnemonic() : null;
    final isEnabled = !isLoading && validMnemonic != null;

    return PrimaryButton(
      text: t.setup_import_button,
      isLoading: isLoading,
      isEnabled: isEnabled,
      onPressed: () async {
        if (validMnemonic == null) return;

        loadingNotifier.state = true;
        notifier.setLoading(true);

        // If a previous wallet exists, wipe its on-disk artifacts
        // (LWK db, Breez working dir) so the new wallet starts clean.
        // V2 boot will re-acquire these dirs through `WalletDirectoryGuard`.
        try {
          final existingMnemonicOption = await ref.read(
            mnemonicProvider.future,
          );
          final hasExistingWallet = existingMnemonicOption.isSome();

          if (hasExistingWallet) {

            final guard = ref.read(walletDirectoryGuardProvider);
            final cleanUseCase = CleanWorkingDirsUseCase(
              directoryGuard: guard,
              workingDirs: _walletWorkingDirs,
            );
            final result = await cleanUseCase();
            result.match(
              (failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.setup_import_cleanup_warning)),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              (_) {/* clean — proceed */},
            );
          }
        } catch (_) {
          // Cleanup is best-effort; proceed even on unexpected errors.
        }

        final result =
            await mnemonicController.saveMnemonic(validMnemonic).run();
        result.match(
          (failure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(failure)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            loadingNotifier.state = false;
            notifier.setLoading(false);
          },
          (success) async {
            loadingNotifier.state = false;
            notifier.setLoading(false);

            ref.invalidate(mnemonicProvider);
            ref.invalidate(balanceCacheProvider);
            ref.invalidate(transactionHistoryCacheProvider);

            if (context.mounted) {
              context.push("/setup/pin/new");
            }
          },
        );
      },
    );
  }
}

