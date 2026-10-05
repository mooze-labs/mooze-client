import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../../infra/core/core_dto_mapper.dart';
import '../models.dart';
import 'session_manager_service.dart';

/// [SessionManagerService] over mooze-core.
///
/// The core signs the login challenge, stores the tokens under `jwt` and
/// `refresh_token`, and coalesces concurrent token operations.
class CoreSessionManagerService implements SessionManagerService {
  CoreSessionManagerService(this._core);

  final Future<MoozeCore> Function() _core;

  static const _refreshKey = 'refresh_token';
  static const _jwtKey = 'jwt';

  @override
  TaskEither<String, Session> getSession() =>
      _session((core) => core.authAccessToken());

  @override
  TaskEither<String, Session> forceRefresh() =>
      _session((core) => core.authForceRefresh());

  /// The core refreshes its stored session. [session] only names the
  /// caller's view of it.
  @override
  TaskEither<String, Session> refreshSession(Session session) => forceRefresh();

  @override
  TaskEither<String, Unit> saveSession(Session session) => _run((core) async {
        await core.securePut(key: _jwtKey, value: session.jwt);
        await core.securePut(key: _refreshKey, value: session.refreshToken);
        // The core caches the session in memory. A reset reads it again.
        await core.authReset();
      });

  @override
  TaskEither<String, Unit> deleteSession() =>
      _run((core) => core.authInvalidate());

  @override
  TaskEither<String, Unit> resetIdentity() => _run((core) => core.authReset());

  TaskEither<String, Session> _session(
    Future<String> Function(MoozeCore core) token,
  ) {
    return TaskEither.tryCatch(() async {
      final core = await _core();
      final jwt = await token(core);
      final refresh = await core.secureGet(key: _refreshKey);
      return Session(jwt: jwt, refreshToken: refresh ?? '');
    }, (e, _) => _message(e));
  }

  TaskEither<String, Unit> _run(Future<void> Function(MoozeCore core) op) {
    return TaskEither.tryCatch(() async {
      await op(await _core());
      return unit;
    }, (e, _) => _message(e));
  }

  static String _message(Object e) => e is CoreError ? coreErrorMessage(e) : '$e';
}
