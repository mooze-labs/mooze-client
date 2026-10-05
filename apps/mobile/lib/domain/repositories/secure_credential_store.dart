import 'package:fpdart/fpdart.dart';

import '../entities/wallet_credentials.dart';
import '../failures/failure.dart';

/// Persists the wallet mnemonic in the platform secure store.
abstract interface class SecureCredentialStore {
  Future<Either<CredentialFailure, WalletCredentials>> load();
  Future<Either<CredentialFailure, Unit>> save(WalletCredentials credentials);
  Future<Either<CredentialFailure, Unit>> delete();
  Future<Either<CredentialFailure, bool>> exists();
}
