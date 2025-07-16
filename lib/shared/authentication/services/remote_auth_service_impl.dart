import 'package:fpdart/fpdart.dart';

import 'package:dio/dio.dart';

import '../models.dart';
import 'remote_auth_service.dart';
import '../clients/signature_client.dart';

const _timeout = Duration(seconds: 10);

class RemoteAuthServiceImpl implements RemoteAuthenticationService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app/v1/",
      ),
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
  );

  final SignatureClient signatureClient;

  RemoteAuthServiceImpl({required this.signatureClient});

  @override
  TaskEither<String, AuthChallenge> requestLoginChallenge(
    String userId,
    String pubKey,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await dio.post(
        '/auth/login',
        data: {'user_id': userId, 'pub_key': pubKey, 'mode': 'login'},
      );
      return AuthChallenge.fromJson(response.data);
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, Session> signChallenge(AuthChallenge challenge) {
    final challengeStr =
        '${challenge.nonce}:${challenge.pubkeyFpr}:${challenge.timestamp}';
    final signedChallenge = signatureClient.signMessage(challengeStr);

    return TaskEither.fromEither(signedChallenge).flatMap(
      (signature) => TaskEither.tryCatch(() async {
        final response = await dio.post(
          '/auth/sign_challenge',
          data: {'challenge_id': challenge.challengeId, 'signature': signature},
        );
        return Session.fromJson(response.data);
      }, (error, stackTrace) => error.toString()),
    );
  }
}
