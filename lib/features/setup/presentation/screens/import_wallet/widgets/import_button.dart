import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../providers/seed_phrase_provider.dart';
import '../providers/import_loading_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);
    final notifier = ref.read(seedPhraseProvider.notifier);
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

        // V2 import use case handles the full pre-import sequence:
        //   1. PIN / pending-tx / walletId hooks (cross-wallet R2/R9 fix)
        //   2. wipe V2 mooze_v2.db (cross-wallet R1 fix)
        //   3. wipe lwk-db + breez working dirs (G15 fix)
        //   4. persist mnemonic via V2 SecureCredentialStore
        //
        // The legacy `mnemonicController.saveMnemonic` path is retired —
        // both V2 and legacy paths write the same `mnemonic_mainWallet`
        // secure-storage key, so existing wallets remain readable.
        final importUseCase =
            await ref.read(importWalletUseCaseProvider.future);
        final result = await importUseCase(WalletCredentials(
          mnemonic: validMnemonic,
          network: AppNetwork.mainnet,
        ));

        result.match(
          (failure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(failure.message)),
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
          (_) {
            loadingNotifier.state = false;
            notifier.setLoading(false);

            // Invalidate legacy caches so any straggler reads of the
            // legacy mnemonic / balance / tx caches re-evaluate against
            // the freshly imported wallet.
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
