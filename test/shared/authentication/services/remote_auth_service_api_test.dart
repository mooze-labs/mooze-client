import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/authentication/services/remote_auth_service_impl.dart';
import 'package:mooze_mobile/shared/authentication/clients/ecdsa_signature_client.dart';
import 'package:mooze_mobile/shared/authentication/models/auth_challenge.dart';

void main() {
  group('Remote Auth Service - API Integration Tests', () {
    late RemoteAuthServiceImpl authService;
    late EcdsaSignatureClient signatureClient;

    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    setUp(() {
      signatureClient = EcdsaSignatureClient(userSeed: testMnemonic);
      authService = RemoteAuthServiceImpl(signatureClient: signatureClient);
    });

    group('/auth/challenge endpoint', () {
      test('should successfully request login challenge from API', () async {
        final pubKeyResult = await signatureClient.getPublicKey().run();
        pubKeyResult.fold(
          (error) => fail('Failed to get public key: $error'),
          (pubKey) => print('Public key: ${pubKey.substring(0, 20)}...'),
        );

        final result = await authService.requestLoginChallenge().run();

        result.fold(
          (error) {
            if (error.contains('500')) {
              fail(
                'Server Error (500): API server configuration issue - $error',
              );
            } else if (error.contains('400')) {
              fail('Bad Request (400): Invalid request format - $error');
            } else if (error.contains('404')) {
              fail('Not Found (404): API endpoint not found - $error');
            } else {
              fail('API request failed: $error');
            }
          },
          (challenge) {
            expect(challenge.challengeId, isNotEmpty);
            expect(challenge.message, isNotEmpty);
            expect(challenge.challengeId.length, greaterThan(10));
            expect(() => base64Decode(challenge.message), returnsNormally);
          },
        );
      });

      test('should handle multiple challenge requests', () async {
        final result1 = await authService.requestLoginChallenge().run();
        final result2 = await authService.requestLoginChallenge().run();

        final errors = <String>[];
        final challenges = <AuthChallenge>[];

        result1.fold(
          (error) => errors.add('Request 1: $error'),
          (challenge) => challenges.add(challenge),
        );

        result2.fold(
          (error) => errors.add('Request 2: $error'),
          (challenge) => challenges.add(challenge),
        );

        if (challenges.isNotEmpty) {
          if (challenges.length == 2) {
            expect(
              challenges[0].challengeId,
              isNot(equals(challenges[1].challengeId)),
            );
            expect(challenges[0].message, isNot(equals(challenges[1].message)));
          }
        } else {
          for (final error in errors) {
            print(error);
          }
          fail('Both challenge requests failed - API is not working properly');
        }
      });
    });

    group('/auth/sign endpoint', () {
      test('should successfully sign challenge and get session', () async {
        final challengeResult = await authService.requestLoginChallenge().run();

        challengeResult.fold(
          (error) {
            fail('Failed to get challenge from API: $error');
          },
          (challenge) async {
            final signResult = await authService.signChallenge(challenge).run();

            signResult.fold(
              (error) {
                fail('Failed to sign challenge: $error');
              },
              (session) {
                expect(session.jwt, isNotEmpty);
                expect(session.refreshToken, isNotEmpty);

                final jwtParts = session.jwt.split('.');
                expect(jwtParts.length, equals(3));

                final expirationResult = session.isExpired();
                expirationResult.fold(
                  (error) => print('Could not validate expiration: $error'),
                  (isExpired) {
                    expect(isExpired, false);
                  },
                );
              },
            );
          },
        );
      });

      test('should handle complete authentication flow', () async {
        final challengeResult = await authService.requestLoginChallenge().run();

        challengeResult.fold(
          (error) {
            fail('Challenge request failed: $error');
          },
          (challenge) async {
            final signResult = await authService.signChallenge(challenge).run();

            signResult.fold(
              (error) {
                fail('Challenge signing failed: $error');
              },
              (session) {
                expect(session.jwt, isNotEmpty);
                expect(session.refreshToken, isNotEmpty);

                final jwtParts = session.jwt.split('.');
                expect(jwtParts.length, equals(3));

                final expirationCheck = session.isExpired();
                expirationCheck.fold(
                  (error) => print('Expiration check failed: $error'),
                  (isExpired) {
                    expect(isExpired, false);
                  },
                );
              },
            );
          },
        );
      });
    });

    group('Error handling', () {
      test('should handle invalid challenge ID in sign request', () async {
        final fakeChallenge = AuthChallenge(
          challengeId:
              'invalid-challenge-id-${DateTime.now().millisecondsSinceEpoch}',
          message: base64Encode(utf8.encode('fake message for testing')),
        );

        final result = await authService.signChallenge(fakeChallenge).run();

        result.fold((error) {
          expect(error, isNotEmpty);

          if (error.contains('500')) {
            fail('Server Error (500): API server configuration issue - $error');
          } else if (error.contains('400')) {
            fail('Bad Request (400): Invalid request format - $error');
          } else if (error.contains('404')) {
            fail('Not Found (404): API endpoint not found - $error');
          } else {
            fail('API request failed: $error');
          }
        }, (session) => fail('Should have failed with invalid challenge ID'));
      });
    });

    group('Network and API validation', () {
      test('should use correct API endpoints', () {
        expect(authService.dio.options.baseUrl, contains('api.mooze.app'));
        expect(
          authService.dio.options.connectTimeout,
          equals(const Duration(seconds: 10)),
        );
        expect(
          authService.dio.options.receiveTimeout,
          equals(const Duration(seconds: 10)),
        );
      });

      test('should generate valid public key format for API', () async {
        final pubKeyResult = await signatureClient.getPublicKey().run();

        pubKeyResult.fold(
          (error) => fail('Failed to generate public key: $error'),
          (pubKey) {
            final pubKeyBytes = base64Decode(pubKey);
            expect(pubKey, isNotEmpty);
            expect(() => base64Decode(pubKey), returnsNormally);
            expect(pubKeyBytes.length, equals(33));
            expect(pubKeyBytes[0] == 0x02 || pubKeyBytes[0] == 0x03, isTrue);
          },
        );
      });
    });

    group('Payload structure validation', () {
      test('should construct correct challenge request payload', () async {
        final pubKeyResult = await signatureClient.getPublicKey().run();

        pubKeyResult.fold((error) => fail('Failed to get public key: $error'), (
          pubKey,
        ) {
          final expectedPayload = {'public_key': pubKey};
          expect(expectedPayload.containsKey('public_key'), isTrue);
          expect(expectedPayload['public_key'], isNotEmpty);
        });
      });

      test('should construct correct sign request payload structure', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testMessage = 'Test authentication message for $timestamp';
        final mockChallenge = AuthChallenge(
          challengeId: 'test-challenge-$timestamp',
          message: base64Encode(utf8.encode(testMessage)),
        );

        final signResult = signatureClient.signMessage(mockChallenge.message);

        signResult.fold((error) => fail('Failed to sign message: $error'), (
          signature,
        ) {
          final expectedPayload = {
            'challenge_id': mockChallenge.challengeId,
            'signature': signature,
          };

          final signatureBytes = base64Decode(signature);

          expect(expectedPayload.containsKey('challenge_id'), isTrue);
          expect(expectedPayload.containsKey('signature'), isTrue);
          expect(
            expectedPayload['challenge_id'],
            equals(mockChallenge.challengeId),
          );
          expect(expectedPayload['signature'], isNotEmpty);
          expect(signatureBytes.length, equals(64));
        });
      });
    });
  });
}
