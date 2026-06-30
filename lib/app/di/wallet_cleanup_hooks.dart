import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import '../../features/pix/receive_pix/data/datasources/pix_deposit_db.dart';
import '../../features/pix/receive_pix/data/services/lbtc_warning_service.dart';
import '../../features/pix/shared/data/services/pix_onboarding_service.dart';
import '../../features/pix/shared/data/services/pix_tutorial_service.dart';
import '../../features/wallet/data/services/wallet_id_service.dart';
import '../../features/wallet/data/storage/balance_snapshot_storage.dart';
import '../../features/wallet/data/storage/pending_transaction_storage.dart';
import '../../shared/authentication/providers.dart';
import '../../shared/infra/db/providers.dart';
import '../../shared/key_management/store/key_store_impl.dart';
import '../../shared/key_management/store/pin_store_impl.dart';
import '../../shared/user/providers/user_service_provider.dart';
import '../../shared/user/services/user_level_storage_service.dart';



Future<void> Function() buildSessionCleanupHook(Ref ref) {
  return () async {
    await ref.read(sessionManagerServiceProvider).deleteSession().run();
  };
}

Future<void> Function() buildPixCleanupHook(Ref ref) {
  return () async {
    final db = ref.read(appDatabaseProvider);
    await PixDepositDatabase(db).clearAllDeposits().run();
    await db.deleteAllFavoritePayers();
    ref.invalidate(favoritePayersControllerProvider);

    final prefs = ref.read(sharedPreferencesProvider);
    final onboarding = PixOnboardingService(prefs);
    await onboarding.resetFirstTimeDialog();
    await onboarding.resetMerchantFirstTimeDialog();
    await PixTutorialService(prefs).resetTutorial();
    await LbtcWarningService().resetWarning();
    await prefs.remove('pix_favorite_payers');
  };
}

List<Future<void> Function()> buildLegacyCleanupHooks() {
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
    () async {
      // Persisted balance snapshots. Wipe ALL of them (not just the current
      // wallet's) so no prior wallet's cached balances can ever surface in a
      // freshly created or imported wallet. Safe under the single-wallet-at-
      // a-time invariant — there is never a second live wallet to preserve.
      await SharedPreferencesBalanceSnapshotStore().clearAll();
    },
    () async {

      final prefs = await SharedPreferences.getInstance();
      await UserLevelStorageService(prefs).clearVerificationLevel();
    },
  ];
}

List<Future<void> Function()> buildWalletCleanupHooks(Ref ref) {
  return [
    buildSessionCleanupHook(ref),
    buildPixCleanupHook(ref),
    ...buildLegacyCleanupHooks(),
  ];
}
