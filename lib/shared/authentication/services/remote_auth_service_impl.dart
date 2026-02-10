import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

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
        defaultValue: "https://api.mooze.app",
      ),
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final SignatureClient signatureClient;

  RemoteAuthServiceImpl({required this.signatureClient});

  factory RemoteAuthServiceImpl.withEcdsaClient(String userMnemonic) {
    return RemoteAuthServiceImpl(
      signatureClient: EcdsaSignatureClient(userSeed: userMnemonic),
    );
  }

  @override
  TaskEither<String, AuthChallenge> requestLoginChallenge() {
    final isSafe =
        kReleaseMode
            ? TaskEither<String, bool>.tryCatch(
              () async => await SafeDevice.isSafeDevice,
              (error, stackTrace) => error.toString(),
            )
            : TaskEither<String, bool>.right(true);

    return isSafe.flatMap((safe) {
      if (!safe) return TaskEither.left("Unsafe device detected");

      return signatureClient.getPublicKey().flatMap(
        (pubKey) => TaskEither.tryCatch(
          () async {
            final requestData = {'public_key': pubKey};

            final response = await dio.post(
              '/auth/challenge',
              data: requestData,
            );
            return AuthChallenge.fromJson(response.data);
          },
          (error, stackTrace) {
            return error.toString();
          },
        ),
      );
    });
  }

  @override
  TaskEither<String, Session> signChallenge(AuthChallenge challenge) {
    final signedChallenge = signatureClient.signMessage(challenge.message);

    return TaskEither.fromEither(signedChallenge).flatMap(
      (signature) => TaskEither.tryCatch(
        () async {
          final requestData = {
            'challenge_id': challenge.challengeId,
            'signature': signature,
          };

          final response = await dio.post('/auth/sign', data: requestData);
          return Session.fromJson(response.data);
        },
        (error, stackTrace) {
          return error.toString();
        },
      ),
    );
  }
}
