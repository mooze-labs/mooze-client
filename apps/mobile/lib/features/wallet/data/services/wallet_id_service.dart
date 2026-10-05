import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';

/// Manages a wallet-scoped identifier that scopes per-wallet history
/// (Swaps, Pegs) so a freshly imported wallet does not see the previous
/// wallet's audit rows.
///
/// Properties (per spec):
///   - Random UUID v4, generated lazily on first read.
///   - Persisted in secure storage so it is stable across app restarts.
///   - Independent of the mnemonic: deriving from the mnemonic would link
///     two devices that imported the same seed, which we explicitly do not
///     want. Reinstalling a wallet on a new device produces a fresh
///     walletId, isolating its audit log.
///   - Wiped by [WalletDataManager.deleteWallet] so the next created or
///     imported wallet starts on a fresh id.
class WalletIdService {
  static const String _storageKey = 'wallet_id';
  static const Uuid _uuid = Uuid();

  final FlutterSecureStorage _storage;

  WalletIdService({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageProvider.instance;

  /// Returns the current walletId, generating and persisting one if absent.
  ///
  /// First read after install or after [clear] generates a new UUID v4 and
  /// writes it to secure storage atomically; subsequent reads return the
  /// persisted value.
  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final fresh = _uuid.v4();
    await _storage.write(key: _storageKey, value: fresh);
    return fresh;
  }

  /// Wipes the persisted walletId. CONTRACT: only ever called from
  /// [WalletDataManager.deleteWallet]. Any other caller violates the
  /// "stable across app restarts" guarantee.
  Future<void> clear() => _storage.delete(key: _storageKey);
}
