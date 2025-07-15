import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../../domain/service.dart';

class RemoteAuthRepositoryImpl implements RemoteAuthenticationRepository {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app/v1/",
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final CryptographyService cryptographyService;

  RemoteAuthRepositoryImpl({required this.cryptographyService});

  @override
  TaskEither<String, AuthenticationChallenge> requestLoginChallenge(
    String userId,
    String pubKey,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await dio.post(
        '/auth/login',
        data: {'user_id': userId, 'pub_key': pubKey, 'mode': 'login'},
      );
      return AuthenticationChallenge.fromJson(response.data);
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, String> signChallenge(AuthenticationChallenge challenge) {
    final challengeStr =
        '${challenge.nonce}:${challenge.pubkeyFpr}:${challenge.timestamp}';
    final signedChallenge = cryptographyService.signMessage(challengeStr);

    return TaskEither.fromEither(signedChallenge).flatMap(
      (signature) => TaskEither.tryCatch(() async {
        final response = await dio.post(
          '/auth/sign_challenge',
          data: {'challenge_id': challenge.challengeId, 'signature': signature},
        );
        return response.data['token'] as String;
      }, (error, stackTrace) => error.toString()),
    );
  }
}
