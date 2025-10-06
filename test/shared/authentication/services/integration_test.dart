import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/authentication/clients/ecdsa_signature_client.dart';
import 'package:mooze_mobile/shared/authentication/models/auth_challenge.dart';

void main() {
  group('ECDSA Authentication Integration Tests', () {
    late EcdsaSignatureClient signatureClient;

    const testSeed = 'integration-test-seed-12345';

    setUp(() {
      signatureClient = EcdsaSignatureClient(userSeed: testSeed);
    });

    group('Authentication Challenge Signing', () {
      test('should sign challenge message correctly', () {
        // Arrange
        const challengeId = 'test-challenge-456';
        const nonce = 'test-nonce-2';
        const pubkeyFpr = 'test-fingerprint-2';
        const timestamp = '2023-10-06T13:00:00Z';
        const testMessage = 'specific message to sign';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        final challenge = AuthChallenge(
          challengeId: challengeId,
          nonce: nonce,
          pubkeyFpr: pubkeyFpr,
          timestamp: timestamp,
          message: messageBase64,
        );

        // Act
        final result = signatureClient.signMessage(challenge.message);

        // Assert
        expect(result.isRight(), true);

        final signature = result.fold((l) => '', (r) => r);
        expect(signature.isNotEmpty, true);

        // Verify it's valid base64
        expect(() => base64Decode(signature), returnsNormally);

        // Verify signature format (should be 64 bytes for compact format)
        final signatureBytes = base64Decode(signature);
        expect(signatureBytes.length, equals(64));
      });

      test('should handle different challenge messages consistently', () {
        // Test with different message contents
        final messages = [
          'Hello World',
          'Test message with numbers 123456',
          'Special chars: !@#\$%^&*()',
          'Unicode: 🔐🚀💎',
          'Long message: ${'a' * 1000}',
        ];

        for (final message in messages) {
          final messageBase64 = base64Encode(utf8.encode(message));
          final challenge = AuthChallenge(
            challengeId: 'test-$message',
            nonce: 'nonce',
            pubkeyFpr: 'fingerprint',
            timestamp: DateTime.now().toIso8601String(),
            message: messageBase64,
          );

          final result = signatureClient.signMessage(challenge.message);

          expect(
            result.isRight(),
            true,
            reason: 'Failed for message: $message',
          );

          final signature = result.fold((l) => '', (r) => r);
          expect(signature.isNotEmpty, true);

          final signatureBytes = base64Decode(signature);
          expect(signatureBytes.length, equals(64));
        }
      });

      test('should produce different signatures for different messages', () {
        // Arrange
        final challenge1 = AuthChallenge(
          challengeId: 'challenge1',
          nonce: 'nonce1',
          pubkeyFpr: 'fp1',
          timestamp: '2023-01-01T00:00:00Z',
          message: base64Encode(utf8.encode('message 1')),
        );

        final challenge2 = AuthChallenge(
          challengeId: 'challenge2',
          nonce: 'nonce2',
          pubkeyFpr: 'fp2',
          timestamp: '2023-01-02T00:00:00Z',
          message: base64Encode(utf8.encode('message 2')),
        );

        // Act
        final signature1 = signatureClient.signMessage(challenge1.message);
        final signature2 = signatureClient.signMessage(challenge2.message);

        // Assert
        expect(signature1.isRight(), true);
        expect(signature2.isRight(), true);

        final sig1 = signature1.fold((l) => '', (r) => r);
        final sig2 = signature2.fold((l) => '', (r) => r);

        expect(sig1, isNot(equals(sig2)));
      });

      test('should handle malformed base64 in challenge gracefully', () {
        // Arrange
        final invalidChallenge = AuthChallenge(
          challengeId: 'test',
          nonce: 'test',
          pubkeyFpr: 'test',
          timestamp: 'test',
          message: 'invalid-base64-content',
        );

        // Act
        final result = signatureClient.signMessage(invalidChallenge.message);

        // Assert - Should handle the error gracefully
        expect(result.isLeft(), true);

        final error = result.fold((l) => l, (r) => '');
        expect(error.toLowerCase().contains('erro'), true);
      });
    });

    group('Cross-Implementation Consistency', () {
      test('should produce consistent public keys', () async {
        // Test multiple instances with same seed
        final client1 = EcdsaSignatureClient(userSeed: testSeed);
        final client2 = EcdsaSignatureClient(userSeed: testSeed);

        final pubKey1Result = await client1.getPublicKey().run();
        final pubKey2Result = await client2.getPublicKey().run();

        expect(pubKey1Result.isRight(), true);
        expect(pubKey2Result.isRight(), true);

        final pubKey1 = pubKey1Result.fold((l) => '', (r) => r);
        final pubKey2 = pubKey2Result.fold((l) => '', (r) => r);

        expect(pubKey1, equals(pubKey2));
      });

      test('should be compatible with both signature formats', () {
        // Arrange
        const testMessage = 'format compatibility test';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act - Test compact format (default)
        final compactResult = signatureClient.signMessage(messageBase64);

        // Act - Test DER format
        final derResult = signatureClient.signMessageDer(messageBase64);

        // Assert
        expect(compactResult.isRight(), true);
        expect(derResult.isRight(), true);

        final compactSig = compactResult.fold((l) => '', (r) => r);
        final derSig = derResult.fold((l) => '', (r) => r);

        final compactBytes = base64Decode(compactSig);
        final derBytes = base64Decode(derSig);

        // Compact should be 64 bytes, DER should be larger
        expect(compactBytes.length, equals(64));
        expect(derBytes.length, greaterThan(64));

        // DER should start with SEQUENCE tag
        expect(derBytes[0], equals(0x30));
      });
    });

    group('Performance and Reliability', () {
      test('should handle multiple signature operations efficiently', () {
        const iterations = 50;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          final message = 'Performance test message $i';
          final messageBase64 = base64Encode(utf8.encode(message));

          final result = signatureClient.signMessage(messageBase64);
          expect(result.isRight(), true);
        }

        stopwatch.stop();

        // Should complete 50 signatures in less than 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Average should be less than 100ms per signature
        final averageTime = stopwatch.elapsedMilliseconds / iterations;
        expect(averageTime, lessThan(100));
      });

      test('should handle concurrent signature operations', () async {
        const concurrentOperations = 10;
        final futures = <Future<bool>>[];

        for (int i = 0; i < concurrentOperations; i++) {
          futures.add(
            Future(() {
              final message = 'Concurrent test $i';
              final messageBase64 = base64Encode(utf8.encode(message));
              final result = signatureClient.signMessage(messageBase64);
              return result.isRight();
            }),
          );
        }

        final results = await Future.wait(futures);

        // All operations should succeed
        expect(results.every((success) => success), true);
      });

      test('should be memory efficient with large messages', () {
        // Test with a large message (1MB)
        final largeMessage = 'x' * (1024 * 1024);
        final messageBase64 = base64Encode(utf8.encode(largeMessage));

        final result = signatureClient.signMessage(messageBase64);

        expect(result.isRight(), true);

        final signature = result.fold((l) => '', (r) => r);
        final signatureBytes = base64Decode(signature);

        // Signature size should remain constant regardless of message size
        expect(signatureBytes.length, equals(64));
      });
    });
  });
}
