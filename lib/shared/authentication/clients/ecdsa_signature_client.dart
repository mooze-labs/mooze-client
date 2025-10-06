import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pointycastle/export.dart';

import 'signature_client.dart';

/// Custom implementation of ECDSA secp256k1 signature
class EcdsaSignatureClient implements SignatureClient {
  final String _userSeed;
  late ECPrivateKey _privateKey;
  late ECPublicKey _publicKey;

  EcdsaSignatureClient({required String userSeed}) : _userSeed = userSeed {
    _initializeKeyPair();
  }

  /// Initializes the ECDSA key pair from the user's seed
  void _initializeKeyPair() {
    // Generates the private key from the seed using PBKDF2
    final keyPair = _generateEcdsaKeyPair(_userSeed);
    _privateKey = keyPair.privateKey;
    _publicKey = keyPair.publicKey;
  }

  /// Generates an ECDSA secp256k1 key pair from a seed string
  AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateEcdsaKeyPair(
    String seed,
  ) {
    // Derives a 32-byte key using PBKDF2 with SHA-256
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    // PBKDF2 settings
    final salt = utf8.encode('mooze-ecdsa-salt'); // Fixed salt for consistency
    final params = Pbkdf2Parameters(
      Uint8List.fromList(salt),
      10000,
      32,
    ); // 10k iterations, 32 bytes

    pbkdf2.init(params);

    // Derives the private key
    final seedBytes = utf8.encode(seed);
    final privateKeyBytes = pbkdf2.process(Uint8List.fromList(seedBytes));

    // Creates the ECDSA private key using secp256k1
    final domainParams = ECDomainParameters('secp256k1');
    final privateKeyBigInt = _bytesToBigInt(privateKeyBytes);

    // Ensures the private key is within a valid range (1 < d < n-1)
    final n = domainParams.n;
    final adjustedPrivateKey =
        (privateKeyBigInt % (n - BigInt.one)) + BigInt.one;

    final privateKey = ECPrivateKey(adjustedPrivateKey, domainParams);

    // Generates the public key
    final Q = domainParams.G * adjustedPrivateKey;
    final publicKey = ECPublicKey(Q, domainParams);

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(publicKey, privateKey);
  }

  /// Converts bytes to BigInt
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Converts BigInt to bytes with padding
  Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = <int>[];
    var temp = number;

    while (temp > BigInt.zero) {
      bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp >>= 8;
    }

    // Adds left padding if needed
    while (bytes.length < length) {
      bytes.insert(0, 0);
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Either<String, String> signMessage(String message) {
    return Either.tryCatch(() {
      // Decodes the base64 message
      final messageBytes = base64Decode(message);

      // Signs the message
      final signature = _signBytes(messageBytes);

      // Returns the signature in base64 format
      return base64Encode(signature);
    }, (error, stackTrace) => 'Error signing message: $error');
  }

  /// Signs bytes using ECDSA secp256k1
  /// Supports both compact encoding (64 bytes) and DER encoding
  Uint8List _signBytes(Uint8List messageBytes) {
    // Computes the SHA-256 hash of the message
    final messageHash = sha256.convert(messageBytes).bytes;
    final hashBytes = Uint8List.fromList(messageHash);

    // Initializes a secure RNG
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Creates the ECDSA signer
    final signer = ECDSASigner(SHA256Digest());
    final params = ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(_privateKey),
      secureRandom,
    );

    signer.init(true, params);

    // Signs the hash
    final ecSignature = signer.generateSignature(hashBytes) as ECSignature;

    // By default, returns compact encoding (64 bytes: 32 bytes r + 32 bytes s)
    return _encodeCompactSignature(ecSignature.r, ecSignature.s);
  }

  /// Encodes the signature in compact format (64 bytes)
  Uint8List _encodeCompactSignature(BigInt r, BigInt s) {
    final rBytes = _bigIntToBytes(r, 32);
    final sBytes = _bigIntToBytes(s, 32);

    final compactSignature = Uint8List(64);
    compactSignature.setRange(0, 32, rBytes);
    compactSignature.setRange(32, 64, sBytes);

    return compactSignature;
  }

  /// Encodes the signature in DER format (approximately 70-72 bytes)
  /// Not used by default, but available if needed
  Uint8List _encodeDerSignature(BigInt r, BigInt s) {
    // Basic DER encoding implementation for ECDSA signature
    final rBytes = _encodeAsn1Integer(r);
    final sBytes = _encodeAsn1Integer(s);

    final sequenceLength = rBytes.length + sBytes.length;
    final der = <int>[];

    // SEQUENCE tag
    der.add(0x30);

    // Sequence length
    if (sequenceLength < 0x80) {
      der.add(sequenceLength);
    } else {
      // For longer sequences, a more complex encoding would be needed
      der.add(sequenceLength);
    }

    // Add r and s
    der.addAll(rBytes);
    der.addAll(sBytes);

    return Uint8List.fromList(der);
  }

  /// Encodes a BigInt as an ASN.1 INTEGER
  List<int> _encodeAsn1Integer(BigInt value) {
    final bytes = _bigIntToBytes(value, 32);
    final result = <int>[];

    // INTEGER tag
    result.add(0x02);

    // If the first bit is set, prepend 0x00 to indicate it's positive
    if (bytes[0] & 0x80 != 0) {
      result.add(bytes.length + 1);
      result.add(0x00);
      result.addAll(bytes);
    } else {
      result.add(bytes.length);
      result.addAll(bytes);
    }

    return result;
  }

  @override
  TaskEither<String, String> getPublicKey() {
    return TaskEither.tryCatch(() async {
      // Returns the public key in compressed hexadecimal format (33 bytes)
      final pubKeyPoint = _publicKey.Q!;
      final x = pubKeyPoint.x!.toBigInteger()!;
      final y = pubKeyPoint.y!.toBigInteger()!;

      // Compressed format: 0x02 or 0x03 + x coordinate (32 bytes)
      final prefix = (y & BigInt.one) == BigInt.zero ? 0x02 : 0x03;
      final xBytes = _bigIntToBytes(x, 32);

      final compressedPubKey = Uint8List(33);
      compressedPubKey[0] = prefix;
      compressedPubKey.setRange(1, 33, xBytes);

      return compressedPubKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
    }, (error, stackTrace) => 'Error getting public key: $error');
  }

  /// Additional method to get the signature in DER format if needed
  Either<String, String> signMessageDer(String message) {
    return Either.tryCatch(() {
      // Decodes the base64 message
      final messageBytes = base64Decode(message);

      // Computes the SHA-256 hash of the message
      final messageHash = sha256.convert(messageBytes).bytes;
      final hashBytes = Uint8List.fromList(messageHash);

      // Initializes a secure RNG
      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = <int>[];
      for (int i = 0; i < 32; i++) {
        seeds.add(seedSource.nextInt(256));
      }
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      // Creates the ECDSA signer
      final signer = ECDSASigner(SHA256Digest());
      final params = ParametersWithRandom(
        PrivateKeyParameter<ECPrivateKey>(_privateKey),
        secureRandom,
      );

      signer.init(true, params);

      // Signs the hash
      final ecSignature = signer.generateSignature(hashBytes) as ECSignature;

      // Returns the signature in DER format
      final derSignature = _encodeDerSignature(ecSignature.r, ecSignature.s);
      return base64Encode(derSignature);
    }, (error, stackTrace) => 'Error signing message (DER): $error');
  }
}
