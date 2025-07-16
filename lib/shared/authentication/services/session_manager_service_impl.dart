import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../models.dart';
import '../services.dart';

class SessionManagerServiceImpl implements SessionManagerService {
  SessionManagerServiceImpl({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app/v1/",
      ),
    ),
  );

  @override
  TaskEither<String, Unit> saveSession(Session session) {
    return TaskEither.tryCatch(() async {
      await _secureStorage.write(key: 'jwt', value: session.jwt);
      await _secureStorage.write(
        key: 'refresh_token',
        value: session.refreshToken,
      );

      return unit;
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, Session> getSession() {
    return TaskEither.tryCatch(() async {
      final jwt = await _secureStorage.read(key: 'jwt');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (jwt == null || refreshToken == null) {
        throw Exception('No session found');
      }

      final session = Session(jwt: jwt, refreshToken: refreshToken);
      if (session.isExpired().getOrElse((l) => true)) {
        final newSessionResult = await refreshSession().run();
        return newSessionResult.fold(
          (error) => throw Exception(error),
          (session) => session,
        );
      }

      return session;
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, Unit> deleteSession() {
    return TaskEither.tryCatch(() async {
      await _secureStorage.delete(key: 'jwt');
      await _secureStorage.delete(key: 'refresh_token');
      return unit;
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, Session> refreshSession() {
    return getSession().flatMap((session) {
      return _requestNewJwtToken(session.refreshToken).flatMap((newJwt) {
        final updatedSession = Session(
          jwt: newJwt,
          refreshToken: session.refreshToken,
        );

        saveSession(updatedSession).map((_) => unit);
        return TaskEither.right(updatedSession);
      });
    });
  }

  TaskEither<String, String> _requestNewJwtToken(String refreshToken) {
    return TaskEither.tryCatch(() async {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      return response.data['jwt'];
    }, (error, stackTrace) => error.toString());
  }
}
