import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/wallet/data/services/wallet_id_service.dart';
import '../../features/wallet/data/storage/pending_transaction_storage.dart';
import '../../shared/key_management/store/key_store_impl.dart';
import '../../shared/key_management/store/pin_store_impl.dart';

/// Builds the best-effort cleanup callbacks consumed by both
/// `ImportWalletUseCase.preImportHooks` and
/// `DeleteWalletUseCase.postDeleteHooks`. These touch legacy stores that
/// do not yet have a V2 abstraction (PIN store, pending-tx
/// SharedPreferences, wallet-id secure-storage entry) so the use cases
/// themselves remain decoupled from those concretions.
///
/// Each hook MUST swallow its own errors (the use case logs the failure
/// but does not abort the sequence). Hooks must be idempotent — calling
/// them on a wallet that was already deleted must be a no-op.
List<Future<void> Function()> buildWalletCleanupHooks() {
  return [
    () async {
      // PIN salt + hashed PIN. Both keys are deleted atomically.
      final pin = PinStoreImpl(keyStore: KeyStoreImpl());
      await pin.deletePin().run();
    },
    () async {
      // Pending-tx SharedPreferences. Prevents orphan pending txs from
      // surfacing when a different wallet is imported.
      await PendingTransactionStorage().clearAll();
    },
    () async {
      // walletId secure-storage entry. Audit-log scoping (Swaps/Pegs)
      // re-scopes onto the next generated id on first read.
      await WalletIdService(storage: const FlutterSecureStorage()).clear();
    },
  ];
}
