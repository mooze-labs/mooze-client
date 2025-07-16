import 'package:fpdart/fpdart.dart';

import '../models.dart';

abstract class SessionManagerService {
  TaskEither<String, Unit> saveSession(Session session);
  TaskEither<String, Session> getSession();
  TaskEither<String, Unit> deleteSession();
  TaskEither<String, Unit> refreshSession();

  /// Get a valid session, automatically refreshing if expired or near expiry
  TaskEither<String, Session> getValidSession({
    Duration buffer = const Duration(minutes: 5),
  });

  /// Check if the current session is expired or near expiry
  TaskEither<String, bool> isSessionExpiredOrNearExpiry({
    Duration buffer = const Duration(minutes: 5),
  });
}
