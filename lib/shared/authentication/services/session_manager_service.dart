import 'package:fpdart/fpdart.dart';

import '../models.dart';

/// Single source of truth for the authentication session lifecycle.
abstract class SessionManagerService {
  /// Persist [session] atomically.
  TaskEither<String, Unit> saveSession(Session session);

  /// Return a valid (non-expired) session. Concurrent callers MUST share the
  /// same resolution and the same network requests.
  TaskEither<String, Session> getSession();

  /// Erase the persisted session atomically.
  TaskEither<String, Unit> deleteSession();

  /// Refresh the JWT for [session]. Concurrent calls with the same refresh
  /// token are coalesced into one network request.
  TaskEither<String, Session> refreshSession(Session session);

  /// Force a refresh against the currently-stored session regardless of the
  /// local expiry check. Used by network interceptors when the server has
  /// rejected an otherwise-valid-looking JWT (401/403). Concurrent callers
  /// share the in-flight refresh.
  TaskEither<String, Session> forceRefresh();
}
