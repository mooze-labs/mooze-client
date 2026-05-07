import 'package:fpdart/fpdart.dart';

import '../../../../domain/entities/wallet_credentials.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/secure_credential_store.dart';

/// Stores a fresh mnemonic into the secure credential store. The caller
/// (typically a setup screen) is responsible for triggering
/// AppLifecycleController.start() afterwards.
class ImportWalletUseCase {
  ImportWalletUseCase(this._store);
  final SecureCredentialStore _store;

  Future<Either<CredentialFailure, Unit>> call(WalletCredentials creds) =>
      _store.save(creds);
}
