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

      // Create session with expiry information extracted from JWT
      return Session.withExpiry(jwt: jwt, refreshToken: refreshToken);
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
  TaskEither<String, Unit> refreshSession() {
    return getSession().flatMap((session) {
      return _requestNewJwtToken(session.refreshToken).flatMap((newJwt) {
        // Create new session with expiry information
        final updatedSession = Session.withExpiry(
          jwt: newJwt,
          refreshToken: session.refreshToken,
        );
        return saveSession(updatedSession).map((_) => unit);
      });
    });
  }

  @override
  TaskEither<String, Session> getValidSession({
    Duration buffer = const Duration(minutes: 5),
  }) {
    return getSession().flatMap((session) {
      // Check if the session is expired or near expiry
      if (session.isExpiredOrNearExpiry(buffer: buffer)) {
        // Refresh the session and return the new one
        return refreshSession().flatMap((_) => getSession());
      } else {
        // Session is still valid, return as-is
        return TaskEither.right(session);
      }
    });
  }

  @override
  TaskEither<String, bool> isSessionExpiredOrNearExpiry({
    Duration buffer = const Duration(minutes: 5),
  }) {
    return getSession().map(
      (session) => session.isExpiredOrNearExpiry(buffer: buffer),
    );
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
