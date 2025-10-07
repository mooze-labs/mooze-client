import 'package:fpdart/fpdart.dart';

import 'package:dio/dio.dart';

import '../models.dart';
import 'remote_auth_service.dart';
import '../clients/signature_client.dart';
import '../clients/ecdsa_signature_client.dart';

const _timeout = Duration(seconds: 10);

class RemoteAuthServiceImpl implements RemoteAuthenticationService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app/",
      ),
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
  );

  final SignatureClient signatureClient;

  RemoteAuthServiceImpl({required this.signatureClient});

  /// Factory method to create an EcdsaSignatureClient using a mnemonic
  factory RemoteAuthServiceImpl.withEcdsaClient(String userMnemonic) {
    return RemoteAuthServiceImpl(
      signatureClient: EcdsaSignatureClient(userSeed: userMnemonic),
    );
  }

  @override
  TaskEither<String, AuthChallenge> requestLoginChallenge() {
    return signatureClient.getPublicKey().flatMap((pubKey) => TaskEither.tryCatch(() async {
      final response = await dio.post(
        '/auth/challenge',
        data: {'public_key': pubKey},
      );
      return AuthChallenge.fromJson(response.data);
    }, (error, stackTrace) => error.toString())
    );
  }

  @override
  TaskEither<String, Session> signChallenge(AuthChallenge challenge) {
    final signedChallenge = signatureClient.signMessage(challenge.message);

    return TaskEither.fromEither(signedChallenge).flatMap(
      (signature) => TaskEither.tryCatch(() async {
        final response = await dio.post(
          '/auth/sign',
          data: {'challenge_id': challenge.challengeId, 'signature': signature},
        );
        return Session.fromJson(response.data);
      }, (error, stackTrace) => error.toString()),
    );
  }
}
