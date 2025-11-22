import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';

import '../models.dart';
import '../services.dart';

class SessionManagerServiceImpl implements SessionManagerService {
  SessionManagerServiceImpl({RemoteAuthenticationService? remoteAuthService})
    : _remoteAuthService = remoteAuthService;

  final _secureStorage = SecureStorageProvider.instance;
  final RemoteAuthenticationService? _remoteAuthService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app",
      ),
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      sendTimeout: Duration(seconds: 10),
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
        if (_remoteAuthService == null) {
          throw Exception(
            'Sessão não encontrada e RemoteAuthService não disponível',
          );
        }

        final newSessionResult = await _createNewSession().run();
        return newSessionResult.fold(
          (error) => throw Exception('Erro ao criar nova sessão: $error'),
          (session) => session,
        );
      }

      final session = Session(jwt: jwt, refreshToken: refreshToken);
      final isExpiredResult = session.isExpired();

      if (isExpiredResult.getOrElse((l) => true)) {
        final refreshResult = await refreshSession(session).run();
        return refreshResult.fold((error) async {
          if (error.contains('REFRESH_TOKEN_NOT_FOUND') ||
              error.contains('404') ||
              error.contains('Session not found') ||
              error.contains('Refresh token inválido')) {
            final newSessionResult = await _createNewSession().run();
            return newSessionResult.fold(
              (createError) =>
                  throw Exception('Erro ao criar nova sessão: $createError'),
              (newSession) => newSession,
            );
          }
          throw Exception(error);
        }, (refreshedSession) => refreshedSession);
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
  TaskEither<String, Session> refreshSession(Session session) {
    return _requestNewJwtToken(session.refreshToken)
        .flatMap((newJwt) {
          final updatedSession = Session(
            jwt: newJwt,
            refreshToken: session.refreshToken,
          );
          return saveSession(updatedSession).map((_) => updatedSession);
        })
        .orElse((error) {
          if (error.contains('REFRESH_TOKEN_NOT_FOUND')) {
            return TaskEither.tryCatch(() async {
              await deleteSession().run();

              final newSessionResult = await _createNewSession().run();
              return newSessionResult.fold(
                (createError) =>
                    throw Exception(
                      'Refresh token inválido e falha ao criar nova sessão: $createError',
                    ),
                (newSession) => newSession,
              );
            }, (e, s) => e.toString());
          }
          return TaskEither.left(error);
        });
  }

  TaskEither<String, String> _requestNewJwtToken(String refreshToken) {
    return TaskEither.tryCatch(() async {
      try {
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final jwt = response.data?['jwt'];
        if (jwt == null) {
          throw Exception('JWT_NULL_IN_RESPONSE');
        }

        return jwt as String;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          throw Exception('REFRESH_TOKEN_NOT_FOUND');
        }
        rethrow;
      }
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, Session> _createNewSession() {
    if (_remoteAuthService == null) {
      return TaskEither.left(
        'RemoteAuthService não configurado para criar nova sessão',
      );
    }

    return _remoteAuthService.requestLoginChallenge().flatMap((challenge) {
      return _remoteAuthService.signChallenge(challenge).flatMap((session) {
        return saveSession(session).map((_) => session);
      });
    });
  }
}
