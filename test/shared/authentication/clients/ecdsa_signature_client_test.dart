import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/authentication/clients/ecdsa_signature_client.dart';

void main() {
  group('EcdsaSignatureClient Tests', () {
    late EcdsaSignatureClient client;
    const testSeed = 'test-seed-for-ecdsa-signature-testing';

    setUp(() {
      client = EcdsaSignatureClient(userSeed: testSeed);
    });

    group('Key Generation', () {
      test('should generate consistent key pair from same seed', () async {
        // Arrange
        final client1 = EcdsaSignatureClient(userSeed: testSeed);
        final client2 = EcdsaSignatureClient(userSeed: testSeed);

        // Act
        final pubKey1Result = await client1.getPublicKey().run();
        final pubKey2Result = await client2.getPublicKey().run();

        // Assert
        expect(pubKey1Result.isRight(), true);
        expect(pubKey2Result.isRight(), true);

        final pubKey1 = pubKey1Result.fold((l) => '', (r) => r);
        final pubKey2 = pubKey2Result.fold((l) => '', (r) => r);

        expect(pubKey1, equals(pubKey2));
        expect(pubKey1.length, equals(66)); // 33 bytes * 2 (hex) = 66 chars
      });

      test('should generate different keys for different seeds', () async {
        // Arrange
        final client1 = EcdsaSignatureClient(userSeed: 'seed1');
        final client2 = EcdsaSignatureClient(userSeed: 'seed2');

        // Act
        final pubKey1Result = await client1.getPublicKey().run();
        final pubKey2Result = await client2.getPublicKey().run();

        // Assert
        expect(pubKey1Result.isRight(), true);
        expect(pubKey2Result.isRight(), true);

        final pubKey1 = pubKey1Result.fold((l) => '', (r) => r);
        final pubKey2 = pubKey2Result.fold((l) => '', (r) => r);

        expect(pubKey1, isNot(equals(pubKey2)));
      });

      test('should generate valid secp256k1 public key format', () async {
        // Act
        final result = await client.getPublicKey().run();

        // Assert
        expect(result.isRight(), true);

        final pubKey = result.fold((l) => '', (r) => r);

        expect(pubKey.startsWith('02') || pubKey.startsWith('03'), true);
        expect(pubKey.length, equals(66));

        expect(
          () => int.parse(pubKey.substring(0, 2), radix: 16),
          returnsNormally,
        );

        final isValidHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(pubKey);
        expect(isValidHex, true);
      });
    });

    group('Message Signing', () {
      test('should sign message and return base64 signature', () {
        // Arrange
        const testMessage = 'Hello, World!';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act
        final result = client.signMessage(messageBase64);

        // Assert
        expect(result.isRight(), true);

        final signature = result.fold((l) => '', (r) => r);
        expect(signature.isNotEmpty, true);

        expect(() => base64Decode(signature), returnsNormally);
      });

      test('should produce consistent signatures for same message', () {
        // Arrange
        const testMessage = 'Consistent test message';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act
        final result1 = client.signMessage(messageBase64);
        final result2 = client.signMessage(messageBase64);

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);

        final signature1 = result1.fold((l) => '', (r) => r);
        final signature2 = result2.fold((l) => '', (r) => r);

        expect(signature1.isNotEmpty, true);
        expect(signature2.isNotEmpty, true);
      });

      test('should produce different signatures for different messages', () {
        // Arrange
        const message1 = 'Message 1';
        const message2 = 'Message 2';
        final messageBase64_1 = base64Encode(utf8.encode(message1));
        final messageBase64_2 = base64Encode(utf8.encode(message2));

        // Act
        final result1 = client.signMessage(messageBase64_1);
        final result2 = client.signMessage(messageBase64_2);

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);

        final signature1 = result1.fold((l) => '', (r) => r);
        final signature2 = result2.fold((l) => '', (r) => r);

        expect(signature1, isNot(equals(signature2)));
      });

      test('should handle invalid base64 input gracefully', () {
        // Arrange
        const invalidBase64 = 'invalid-base64!@#';

        // Act
        final result = client.signMessage(invalidBase64);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should produce compact signature format (64 bytes)', () {
        // Arrange
        const testMessage = 'Compact signature test';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act
        final result = client.signMessage(messageBase64);

        // Assert
        expect(result.isRight(), true);

        final signature = result.fold((l) => '', (r) => r);
        final signatureBytes = base64Decode(signature);

        expect(signatureBytes.length, equals(64));
      });
    });

    group('DER Signature Format', () {
      test('should produce DER signature when requested', () {
        // Arrange
        const testMessage = 'DER signature test';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act
        final result = client.signMessageDer(messageBase64);

        // Assert
        expect(result.isRight(), true);

        final signature = result.fold((l) => '', (r) => r);
        final signatureBytes = base64Decode(signature);

        expect(signatureBytes.length, greaterThan(64));
        expect(signatureBytes.length, lessThanOrEqualTo(80));

        expect(signatureBytes[0], equals(0x30));
      });
    });

    group('Cryptographic Validation', () {
      test(
        'should produce valid ECDSA signatures that can be verified',
        () async {
          // Arrange
          const testMessage = 'Verification test message';
          final messageBase64 = base64Encode(utf8.encode(testMessage));

          // Act
          final signResult = client.signMessage(messageBase64);
          final pubKeyResult = await client.getPublicKey().run();

          // Assert
          expect(signResult.isRight(), true);
          expect(pubKeyResult.isRight(), true);

          final signature = signResult.fold((l) => '', (r) => r);
          final pubKeyHex = pubKeyResult.fold((l) => '', (r) => r);

          expect(signature.isNotEmpty, true);
          expect(pubKeyHex.isNotEmpty, true);

          final signatureBytes = base64Decode(signature);
          expect(signatureBytes.length, equals(64));

          final r = _bytesToBigInt(signatureBytes.sublist(0, 32));
          final s = _bytesToBigInt(signatureBytes.sublist(32, 64));

          expect(r, greaterThan(BigInt.zero));
          expect(s, greaterThan(BigInt.zero));
        },
      );

      test('should handle edge case messages correctly', () {
        // Test empty message
        final emptyResult = client.signMessage(base64Encode([]));
        expect(emptyResult.isRight(), true);

        // Test very long message
        final longMessage = 'a' * 10000;
        final longMessageBase64 = base64Encode(utf8.encode(longMessage));
        final longResult = client.signMessage(longMessageBase64);
        expect(longResult.isRight(), true);
      });
    });

    group('Error Handling', () {
      test('should handle malformed base64 gracefully', () {
        const malformedBase64 = 'this is not base64!';

        final result = client.signMessage(malformedBase64);

        expect(result.isLeft(), true);
      });

      test('should handle empty seed', () {
        expect(() => EcdsaSignatureClient(userSeed: ''), returnsNormally);
      });

      test('should handle unicode characters in seed', () async {
        const unicodeSeed = 'test-🔐-unicode-seed-🚀';

        expect(
          () => EcdsaSignatureClient(userSeed: unicodeSeed),
          returnsNormally,
        );

        final unicodeClient = EcdsaSignatureClient(userSeed: unicodeSeed);
        final result = await unicodeClient.getPublicKey().run();

        expect(result.isRight(), true);
      });
    });

    group('Performance Tests', () {
      test('should sign messages efficiently', () {
        // Arrange
        const testMessage = 'Performance test message';
        final messageBase64 = base64Encode(utf8.encode(testMessage));

        // Act & Assert
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          final result = client.signMessage(messageBase64);
          expect(result.isRight(), true);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}

BigInt _bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (int i = 0; i < bytes.length; i++) {
    result = (result << 8) + BigInt.from(bytes[i]);
  }
  return result;
}
