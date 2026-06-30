import 'package:fpdart/fpdart.dart';

import '../../domain/entities/wallet_credentials.dart';
import '../../domain/failures/failure.dart';
import '../../domain/services/session_authenticator.dart';
import '../../shared/logging/structured_logger.dart';

/// Default no-op session authenticator. Returns success immediately so that
/// boot completes even when no API session is configured.
///
/// To wire a real backend, swap this for an impl that calls your API and
/// stores the JWT in secure storage.
class NoOpSessionAuthenticator implements SessionAuthenticator {
  NoOpSessionAuthenticator(this._logger);
  final StructuredLogger _logger;

  @override
  Future<Either<SessionFailure, Unit>> ensure({
    required WalletCredentials credentials,
    Duration? timeout,
  }) async {
    _logger.debug('session.ensure.noop', {});
    return const Right(unit);
  }

  @override
  Future<void> invalidate() async {
    _logger.debug('session.invalidate.noop', {});
  }
}
