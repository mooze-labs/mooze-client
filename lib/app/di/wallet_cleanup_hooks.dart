import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart' show PixFlagDto;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import '../../features/wallet/data/services/wallet_id_service.dart';
import '../../features/wallet/data/storage/balance_snapshot_storage.dart';
import '../../features/wallet/data/storage/pending_transaction_storage.dart';
import '../../shared/authentication/providers.dart';
import '../../shared/infra/db/providers.dart';
import '../../shared/key_management/store/key_store_impl.dart';
import '../../shared/key_management/store/pin_store_impl.dart';
import '../../shared/user/providers/user_service_provider.dart';
import '../../shared/user/services/user_level_storage_service.dart';
import 'v2_providers.dart' show moozeCoreProvider;



/// Deletes the API session and makes the core forget the signing
/// identity of the current mnemonic.
Future<void> Function() buildSessionCleanupHook(Ref ref) {
  return () async {
    final session = ref.read(sessionManagerServiceProvider);
    await session.deleteSession().run();
    await session.resetIdentity().run();
  };
}

/// Makes the core read the mnemonic again on the next auth call. Run it
/// after the mnemonic is written or deleted.
Future<void> Function() buildAuthResetHook(Ref ref) {
  return () async {
    await ref.read(sessionManagerServiceProvider).resetIdentity().run();
  };
}

Future<void> Function() buildPixCleanupHook(Ref ref) {
  return () async {
    // Deposits, favorite payers and the PIX flags live in mooze-core.
    final core = await ref.read(moozeCoreProvider.future);
    await core.pixClearDeposits();
    await core.favoritePayersClear();
    for (final flag in PixFlagDto.values) {
      await core.pixFlagReset(flag: flag);
    }
    ref.invalidate(favoritePayersControllerProvider);

    // The one-time import reads the legacy drift tables and preferences
    // while the core is not migrated. Clear them too, so that a retried
    // import cannot restore the data of a deleted wallet.
    final db = ref.read(appDatabaseProvider);
    await db.deleteAllDeposits();
    await db.deleteAllFavoritePayers();
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in _legacyPixPreferenceKeys) {
      await prefs.remove(key);
    }
  };
}

/// SharedPreferences keys of the PIX data before mooze-core.
const _legacyPixPreferenceKeys = [
  'pix_main_first_time_dialog_shown',
  'pix_merchant_first_time_dialog_shown',
  'hasSeenPixTutorial',
  'lbtc_fluctuation_warning_shown',
  'pix_favorite_payers',
];

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
