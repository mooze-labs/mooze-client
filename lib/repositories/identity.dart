import 'package:cryptography/cryptography.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:hex/hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IdentityRepository {
  final List<int> _publicKey;

  IdentityRepository({required List<int> publicKey}) : _publicKey = publicKey;

  List<int> get publicKey => _publicKey;
  String get mpub => Bech32Encoder.encode("mpub", _publicKey);

  static Future<IdentityRepository> fromSeed(List<int> seed) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(seed);
    final pubKey = await keyPair.extractPublicKey().then(
      (pubKey) => pubKey.bytes,
    );

    return IdentityRepository(publicKey: pubKey);
  }

  static Future<IdentityRepository> fromStorage() async {
    final storage = await SharedPreferences.getInstance();

    final pubKey = storage.getString("identity_pub_key");
    if (pubKey == null) {
      throw Exception("No public key found in storage");
    }

    return IdentityRepository(publicKey: HEX.decode(pubKey));
  }
}

class IdentityKeyStore {
  static const String _privKeyStorageKey = "identity_priv_key";
  static const String _pubKeyStorageKey = "identity_pub_key";

  static Future<void> generateNewKeyPair() async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final privKey = await keyPair.extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey().then(
      (pubKey) => pubKey.bytes,
    );

    await saveKeyPair(pubKey, privKey);
  }

  static Future<void> saveKeyPair(List<int> pubKey, List<int> privKey) async {
    final storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    await storage.write(key: _privKeyStorageKey, value: HEX.encode(privKey));
    await prefs.setString(_pubKeyStorageKey, HEX.encode(pubKey));
  }
}
