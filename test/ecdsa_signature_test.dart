import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/authentication/clients/ecdsa_signature_client.dart';

void main() {
  group('EcdsaSignatureClient Tests', () {
    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    late EcdsaSignatureClient signatureClient;

    setUp(() {
      signatureClient = EcdsaSignatureClient(userSeed: testMnemonic);
    });

    test('should generate consistent public key from same mnemonic', () async {
      final publicKeyResult1 = await signatureClient.getPublicKey().run();
      final publicKeyResult2 = await signatureClient.getPublicKey().run();

      expect(publicKeyResult1.isRight(), true);
      expect(publicKeyResult2.isRight(), true);

      final pubKey1 = publicKeyResult1.getOrElse((l) => '');
      final pubKey2 = publicKeyResult2.getOrElse((l) => '');

      expect(pubKey1, equals(pubKey2));
      expect(
        pubKey1.length,
        equals(66),
      ); // 33 bytes * 2 chars/byte = 66 hex chars
    });

    test('should sign message successfully', () {
      const testMessage = 'SGVsbG8gV29ybGQ='; // "Hello World" in base64

      final signatureResult = signatureClient.signMessage(testMessage);

      expect(signatureResult.isRight(), true);

      final signature = signatureResult.getOrElse((l) => '');
      final signatureBytes = base64Decode(signature);

      // Compact signature should be 64 bytes (32 r + 32 s)
      expect(signatureBytes.length, equals(64));
    });

    test('should generate different signatures for different messages', () {
      const message1 = 'SGVsbG8gV29ybGQ='; // "Hello World"
      const message2 = 'R29vZGJ5ZSBXb3JsZA=='; // "Goodbye World"

      final signature1 = signatureClient.signMessage(message1);
      final signature2 = signatureClient.signMessage(message2);

      expect(signature1.isRight(), true);
      expect(signature2.isRight(), true);

      final sig1 = signature1.getOrElse((l) => '');
      final sig2 = signature2.getOrElse((l) => '');

      expect(sig1, isNot(equals(sig2)));
    });

    test('should generate DER signature successfully', () {
      const testMessage = 'SGVsbG8gV29ybGQ=';

      final derSignatureResult = signatureClient.signMessageDer(testMessage);

      expect(derSignatureResult.isRight(), true);

      final derSignature = derSignatureResult.getOrElse((l) => '');
      final derBytes = base64Decode(derSignature);

      // DER signature should be around 70-72 bytes
      expect(derBytes.length, greaterThanOrEqualTo(68));
      expect(derBytes.length, lessThanOrEqualTo(75));

      // DER should start with SEQUENCE tag (0x30)
      expect(derBytes[0], equals(0x30));
    });

    test('should handle invalid base64 gracefully', () {
      const invalidBase64 = 'invalid-base64!@#';

      final result = signatureClient.signMessage(invalidBase64);

      expect(result.isLeft(), true);
    });

    test('should be deterministic with same mnemonic', () async {
      // Create two clients with same mnemonic
      final client1 = EcdsaSignatureClient(userSeed: testMnemonic);
      final client2 = EcdsaSignatureClient(userSeed: testMnemonic);

      const testMessage = 'SGVsbG8gV29ybGQ=';

      final signature1 = client1.signMessage(testMessage);
      final signature2 = client2.signMessage(testMessage);

      expect(signature1.isRight(), true);
      expect(signature2.isRight(), true);

      // Note: ECDSA signatures are not deterministic due to random k value
      // But the public keys should be the same
      final pubKey1 = await client1.getPublicKey().run();
      final pubKey2 = await client2.getPublicKey().run();

      expect(pubKey1.isRight(), true);
      expect(pubKey2.isRight(), true);
      expect(
        pubKey1.getOrElse((l) => ''),
        equals(pubKey2.getOrElse((l) => '')),
      );
    });
  });
}
