import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../models.dart';
import '../services.dart';

class SessionManagerServiceImpl implements SessionManagerService {
  SessionManagerServiceImpl({
    required FlutterSecureStorage secureStorage,
    RemoteAuthenticationService? remoteAuthService,
  }) : _secureStorage = secureStorage,
       _remoteAuthService = remoteAuthService;

  final FlutterSecureStorage _secureStorage;
  final RemoteAuthenticationService? _remoteAuthService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "http://10.0.2.2:3000",
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
      print('📱 Verificando sessão existente...');
      final jwt = await _secureStorage.read(key: 'jwt');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (jwt == null || refreshToken == null) {
        print('🔑 Nenhuma sessão encontrada, criando nova sessão...');
        final newSessionResult = await _createNewSession().run();
        return newSessionResult.fold(
          (error) => throw Exception('Erro ao criar nova sessão: $error'),
          (session) => session,
        );
      }

      print('📱 Sessão encontrada, verificando expiração...');
      final session = Session(jwt: jwt, refreshToken: refreshToken);
      final isExpiredResult = session.isExpired();
      print('📱 Token expirado? ${isExpiredResult.getOrElse((l) => true)}');

      if (isExpiredResult.getOrElse((l) => true)) {
        print('🔄 Token expirado, tentando refresh...');
        final refreshResult = await refreshSession(session).run();
        return refreshResult.fold((error) async {
          print('❌ Refresh falhou: $error');
          // Se o refresh falhar com 404 (session not found), criar nova sessão
          if (error.contains('404') || error.contains('Session not found')) {
            print('🔑 Refresh falhou com 404, criando nova sessão...');
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

      print('✅ Token válido, usando sessão existente');
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
    return _requestNewJwtToken(session.refreshToken).flatMap((newJwt) {
      final updatedSession = Session(
        jwt: newJwt,
        refreshToken: session.refreshToken,
      );

      return saveSession(updatedSession).map((_) => updatedSession);
    });
  }

  TaskEither<String, String> _requestNewJwtToken(String refreshToken) {
    return TaskEither.tryCatch(() async {
      print('🔄 Tentando refresh token...');
      print('🔄 Base URL: ${_dio.options.baseUrl}');
      print('🔄 Full URL será: ${_dio.options.baseUrl}/auth/refresh');
      print('🔄 Refresh token: ${refreshToken.substring(0, 20)}...');

      try {
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        print('✅ Refresh bem-sucedido: ${response.data}');
        return response.data['jwt'];
      } catch (e) {
        if (e is DioException) {
          print('❌ DioException no refresh:');
          print('   Status Code: ${e.response?.statusCode}');
          print('   Status Message: ${e.response?.statusMessage}');
          print('   Response Data: ${e.response?.data}');
          print('   Request URL: ${e.requestOptions.uri}');
        }
        rethrow;
      }
    }, (error, stackTrace) => error.toString());
  }

  /// Cria uma nova sessão usando o fluxo de autenticação completo
  TaskEither<String, Session> _createNewSession() {
    if (_remoteAuthService == null) {
      return TaskEither.left(
        'RemoteAuthService não configurado para criar nova sessão',
      );
    }

    return _remoteAuthService.requestLoginChallenge().flatMap((challenge) {
      print('🔑 Challenge recebido: ${challenge.challengeId}');
      return _remoteAuthService.signChallenge(challenge).flatMap((session) {
        print('✅ Sessão criada com sucesso');
        // Salvar automaticamente a nova sessão
        return saveSession(session).map((_) => session);
      });
    });
  }
}
