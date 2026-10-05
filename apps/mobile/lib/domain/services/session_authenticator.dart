import 'package:fpdart/fpdart.dart';

import '../entities/wallet_credentials.dart';
import '../failures/failure.dart';

/// Establishes / refreshes the API session. Boot phase calls `ensure`.
/// Failures are non-fatal: app proceeds in degraded (offline) mode.
abstract interface class SessionAuthenticator {
  Future<Either<SessionFailure, Unit>> ensure({
    required WalletCredentials credentials,
    Duration? timeout,
  });
  Future<void> invalidate();
}
