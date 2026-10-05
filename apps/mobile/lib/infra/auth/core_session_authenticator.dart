import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../domain/entities/wallet_credentials.dart';
import '../../domain/failures/failure.dart';
import '../../domain/services/session_authenticator.dart';
import '../../shared/logging/structured_logger.dart';
import '../core/core_dto_mapper.dart';

/// [SessionAuthenticator] over mooze-core.
///
/// The core reads the mnemonic from the secure store, so [ensure] does not
/// use `credentials`. On timeout the core call continues and stores the
/// session when it completes.
class CoreSessionAuthenticator implements SessionAuthenticator {
  CoreSessionAuthenticator({
    required Future<MoozeCore> Function() core,
    required StructuredLogger logger,
  })  : _core = core,
        _logger = logger;

  final Future<MoozeCore> Function() _core;
  final StructuredLogger _logger;

  @override
  Future<Either<SessionFailure, Unit>> ensure({
    required WalletCredentials credentials,
    Duration? timeout,
  }) async {
    final t0 = DateTime.now();
    try {
      final call = _core().then((core) => core.authEnsureSession());
      final result =
          await (timeout == null ? call : call.timeout(timeout));
      _logger.info('session.ensure', {
        'kind': result.kind.name,
        'status_code': result.statusCode,
        'dur_ms': DateTime.now().difference(t0).inMilliseconds,
      });
      if (result.kind == AuthEnsureKind.ready) return const Right(unit);
      return Left(SessionFailure(
          '${result.kind.name}: ${result.message ?? result.statusCode ?? ''}'));
    } on TimeoutException catch (e, st) {
      return Left(SessionFailure('session ensure timed out',
          cause: e, stackTrace: st));
    } catch (e, st) {
      final detail = e is CoreError ? coreErrorMessage(e) : '$e';
      return Left(SessionFailure(detail, cause: e, stackTrace: st));
    }
  }

  @override
  Future<void> invalidate() async {
    try {
      await (await _core()).authInvalidate();
    } catch (e) {
      _logger.warn('session.invalidate.failed', {'error': '$e'});
    }
  }
}
