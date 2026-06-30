import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/chain.dart';
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/secure_credential_store.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../shared/storage/mnemonic_prefetch.dart';

class FlutterSecureCredentialStore implements SecureCredentialStore {
  // Audit (V2_PHASE2_PARITY_AND_MIGRATION §0 Phase 2.0):
  //
  // Legacy `MnemonicStoreImpl` (lib/shared/key_management/store/
  // mnemonic_store_impl.dart) saves the user's mnemonic under
  // `'mnemonic_mainWallet'` via `SecureStorageProvider.instance` with the
  // SAME Android/iOS options we use here (`encryptedSharedPreferences`,
  // `KeychainAccessibility.first_unlock`).
  //
  // V2 must point at the same key + options so the existing wallet on a
  // device upgrading from a legacy build is loaded transparently with no
  // re-import and no migration code. Using a different key would either
  // (a) require a one-shot copy with a window where both keys exist, or
  // (b) force every existing user to re-import — both unacceptable for a
  // strangler-fig migration.
  //
  // Note: the constants `'mnemonic'` in lwk/bdk datasources and the delete
  // path in `WalletDataManager.deleteWallet` are stale — they don't match
  // the actual save target. That's a latent legacy bug (deleteWallet may
  // leave the mnemonic in place); we are NOT porting it. V2's
  // `DeleteWalletUseCase` deletes via this same key, so the V2 path is
  // correct by construction.
  FlutterSecureCredentialStore({
    FlutterSecureStorage? storage,
    this.network = AppNetwork.mainnet,
    this.mnemonicKey = 'mnemonic_mainWallet',
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                  accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;
  final AppNetwork network;
  final String mnemonicKey;

  @override
  Future<Either<CredentialFailure, WalletCredentials>> load() async {
    try {
      // Route through the shared prefetch cache when this is the
      // standard wallet key — eliminates the duplicate Keychain hit
      // that used to cost ~4 s on cold start. For non-standard keys
      // (tests, future multi-wallet support) we still hit the
      // platform channel directly.
      BootTracer.mark('creds.load.start', {'key': mnemonicKey});
      final String? v;
      if (mnemonicKey == MnemonicPrefetch.key) {
        v = await MnemonicPrefetch.get();
      } else {
        v = await _storage.read(key: mnemonicKey);
      }
      BootTracer.mark('creds.load.done', {
        'has_value': v != null && v.isNotEmpty,
        'prefetch_ms': MnemonicPrefetch.durationMs,
      });
      if (v == null || v.isEmpty) {
        return Right(WalletCredentials.absent(network));
      }
      return Right(WalletCredentials(mnemonic: v, network: network));
    } catch (e, st) {
      return Left(CredentialFailure('load failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<CredentialFailure, Unit>> save(
      WalletCredentials credentials) async {
    if (credentials.isAbsent) {
      return Left(const CredentialFailure('refusing to save absent mnemonic'));
    }
    try {
      await _storage.write(key: mnemonicKey, value: credentials.mnemonic);
      // Invalidate the prefetch cache so the next reader picks up the
      // freshly-written value instead of a stale future from a prior
      // wallet (relevant on re-import after delete-and-restore).
      if (mnemonicKey == MnemonicPrefetch.key) {
        MnemonicPrefetch.clear();
      }
      return const Right(unit);
    } catch (e, st) {
      return Left(CredentialFailure('save failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<CredentialFailure, Unit>> delete() async {
    try {
      await _storage.delete(key: mnemonicKey);
      if (mnemonicKey == MnemonicPrefetch.key) {
        MnemonicPrefetch.clear();
      }
      return const Right(unit);
    } catch (e, st) {
      return Left(CredentialFailure('delete failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<CredentialFailure, bool>> exists() async {
    try {
      final v = await _storage.read(key: mnemonicKey);
      return Right(v != null && v.isNotEmpty);
    } catch (e, st) {
      return Left(CredentialFailure('exists failed: $e', cause: e, stackTrace: st));
    }
  }
}
