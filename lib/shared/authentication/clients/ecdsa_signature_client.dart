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
    final keyPair = _generateEcdsaKeyPair(_userSeed);
    _privateKey = keyPair.privateKey;
    _publicKey = keyPair.publicKey;
  }

  /// Generates an ECDSA secp256k1 key pair from a seed string
  AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateEcdsaKeyPair(
    String seed,
  ) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    final salt = utf8.encode('mooze-ecdsa-salt');
    final params = Pbkdf2Parameters(Uint8List.fromList(salt), 10000, 32);

    pbkdf2.init(params);

    final seedBytes = utf8.encode(seed);
    final privateKeyBytes = pbkdf2.process(Uint8List.fromList(seedBytes));

    final domainParams = ECDomainParameters('secp256k1');
    final privateKeyBigInt = _bytesToBigInt(privateKeyBytes);

    final n = domainParams.n;
    final adjustedPrivateKey =
        (privateKeyBigInt % (n - BigInt.one)) + BigInt.one;

    final privateKey = ECPrivateKey(adjustedPrivateKey, domainParams);

    final Q = domainParams.G * adjustedPrivateKey;
    final publicKey = ECPublicKey(Q, domainParams);

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(publicKey, privateKey);
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }

  Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = <int>[];
    var temp = number;

    while (temp > BigInt.zero) {
      bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp >>= 8;
    }

    while (bytes.length < length) {
      bytes.insert(0, 0);
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Either<String, String> signMessage(String message) {
    return Either.tryCatch(() {
      final messageBytes = base64Decode(message);
      final signature = _signBytesDirectly(messageBytes);
      return base64Encode(signature);
    }, (error, stackTrace) => 'Error signing message: $error');
  }

  Uint8List _signBytesDirectly(Uint8List messageBytes) {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final signer = ECDSASigner(null);
    final params = ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(_privateKey),
      secureRandom,
    );

    signer.init(true, params);
    final ecSignature = signer.generateSignature(messageBytes) as ECSignature;

    final canonicalSignature = _canonicalizeSignature(ecSignature);

    return _encodeCompactSignature(
      canonicalSignature.r,
      canonicalSignature.s,
    );
  }

  Either<String, String> signMessageHash(String message) {
    return Either.tryCatch(() {
      final messageBytes = base64Decode(message);
      final messageHash = sha256.convert(messageBytes).bytes;
      final hashBytes = Uint8List.fromList(messageHash);
      final signature = _signBytesDirectly(hashBytes);
      return base64Encode(signature);
    }, (error, stackTrace) => 'Error signing message hash: $error');
  }

  Uint8List _encodeCompactSignature(BigInt r, BigInt s) {
    final rBytes = _bigIntToBytes(r, 32);
    final sBytes = _bigIntToBytes(s, 32);

    final compactSignature = Uint8List(64);
    compactSignature.setRange(0, 32, rBytes);
    compactSignature.setRange(32, 64, sBytes);

    return compactSignature;
  }

  ECSignature _canonicalizeSignature(ECSignature signature) {
    final domainParams = ECDomainParameters('secp256k1');
    final n = domainParams.n;
    final halfN = n >> 1;

    BigInt r = signature.r;
    BigInt s = signature.s;

    if (s > halfN) {
      s = n - s;
    }

    return ECSignature(r, s);
  }

  Uint8List _encodeDerSignature(BigInt r, BigInt s) {
    final rBytes = _encodeAsn1Integer(r);
    final sBytes = _encodeAsn1Integer(s);

    final sequenceLength = rBytes.length + sBytes.length;
    final der = <int>[];

    der.add(0x30);
    if (sequenceLength < 0x80) {
      der.add(sequenceLength);
    } else {
      der.add(sequenceLength);
    }

    der.addAll(rBytes);
    der.addAll(sBytes);

    return Uint8List.fromList(der);
  }

  List<int> _encodeAsn1Integer(BigInt value) {
    final bytes = _bigIntToBytes(value, 32);
    final result = <int>[];

    result.add(0x02);

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
      final pubKeyPoint = _publicKey.Q!;
      final x = pubKeyPoint.x!.toBigInteger()!;
      final y = pubKeyPoint.y!.toBigInteger()!;

      final prefix = (y & BigInt.one) == BigInt.zero ? 0x02 : 0x03;
      final xBytes = _bigIntToBytes(x, 32);

      final compressedPubKey = Uint8List(33);
      compressedPubKey[0] = prefix;
      compressedPubKey.setRange(1, 33, xBytes);

      return base64Encode(compressedPubKey);
    }, (error, stackTrace) => 'Error getting public key: $error');
  }

  Either<String, String> signMessageDer(String message) {
    return Either.tryCatch(() {
      final messageBytes = base64Decode(message);
      final messageHash = sha256.convert(messageBytes).bytes;
      final hashBytes = Uint8List.fromList(messageHash);

      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = <int>[];
      for (int i = 0; i < 32; i++) {
        seeds.add(seedSource.nextInt(256));
      }
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      final signer = ECDSASigner(SHA256Digest());
      final params = ParametersWithRandom(
        PrivateKeyParameter<ECPrivateKey>(_privateKey),
        secureRandom,
      );

      signer.init(true, params);

      final ecSignature = signer.generateSignature(hashBytes) as ECSignature;
      final derSignature = _encodeDerSignature(ecSignature.r, ecSignature.s);
      return base64Encode(derSignature);
    }, (error, stackTrace) => 'Error signing message (DER): $error');
  }
}
