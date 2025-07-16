import 'package:fpdart/fpdart.dart';

import '../models.dart';

abstract class SessionManagerService {
  TaskEither<String, Unit> saveSession(Session session);
  TaskEither<String, Session> getSession();
  TaskEither<String, Unit> deleteSession();
  TaskEither<String, Session> refreshSession();
}
