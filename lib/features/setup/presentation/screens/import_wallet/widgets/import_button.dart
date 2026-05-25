import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
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
        BootTracer.mark('import_button.usecase.resolve.begin');
        final importUseCase =
            await ref.read(importWalletUseCaseProvider.future);
        BootTracer.mark('import_button.usecase.resolve.end');
        BootTracer.mark('import_button.usecase.run.begin');
        final result = await importUseCase(WalletCredentials(
          mnemonic: validMnemonic,
          network: AppNetwork.mainnet,
        ));
        BootTracer.mark('import_button.usecase.run.end',
            {'ok': result.isRight()});

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
          (_) async {
            loadingNotifier.state = false;
            notifier.setLoading(false);

            // Invalidate legacy caches so any straggler reads of the
            // legacy mnemonic / balance / tx caches re-evaluate against
            // the freshly imported wallet.
            BootTracer.mark('import_button.invalidates.begin');
            ref.invalidate(mnemonicProvider);
            BootTracer.mark('import_button.invalidate.mnemonic');
            ref.invalidate(balanceCacheProvider);
            BootTracer.mark('import_button.invalidate.balance');
            ref.invalidate(transactionHistoryCacheProvider);
            BootTracer.mark('import_button.invalidate.tx_history');

            // CRITICAL (2026-05-24): invalidate the V2 transaction
            // notifier. The notifier instance constructed during the
            // pre-import boot has `_importedAtMs = null` cached in
            // memory — when `ImportWalletUseCase` stamps the new
            // import timestamp moments earlier, that in-memory value
            // is NOT refreshed. Without an invalidate, every
            // historical confirmed receive from the freshly-synced
            // wallet (which is older than the stamp) bypasses the
            // `pre_import_drop` filter, ends up in
            // `_pendingEmissions`, and floods the user with N
            // "transaction confirmed" modals the instant they reach
            // /home.
            ref.invalidate(transactionNotifierProvider);
            BootTracer.mark('import_button.invalidate.tx_notifier');
            // Eagerly reconstruct the notifier so it subscribes to
            // the orchestrator's transactions stream BEFORE the
            // post-import boot kicks off its first sync. The
            // notifier's constructor subscribes synchronously, so as
            // long as the Future resolves before any chain emits, no
            // events are missed.
            try {
              await ref.read(transactionNotifierProvider.future);
              BootTracer.mark('import_button.tx_notifier.ready');
            } catch (e) {
              BootTracer.mark('import_button.tx_notifier.error',
                  {'error': e.toString()});
            }
            BootTracer.mark('import_button.invalidates.end');

            if (context.mounted) {
              BootTracer.mark('import_button.nav.pin_new');
              context.push("/setup/pin/new");
            }
          },
        );
      },
    );
  }
}
