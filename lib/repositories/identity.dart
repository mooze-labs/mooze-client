import 'package:dart_nostr/dart_nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NostrKeyStore {
  static const String _privKeyStorageKey = "nostr_priv_key";
  static const String _pubKeyStorageKey = "nostr_pub_key";

  static Future<bool> hasKeyPair() async {
    final storage = await SharedPreferences.getInstance();
    return storage.containsKey(_pubKeyStorageKey);
  }

  static void generateNewKeyPair() async {
    final nostr = Nostr.instance;
    final privKey = nostr.keysService.generatePrivateKey();

    await saveKeyPair(privKey);
  }

  static Future<void> saveKeyPair(String privKey) async {
    final nostr = Nostr.instance;
    final storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    final pubKey = nostr.keysService.derivePublicKey(privateKey: privKey);

    await storage.write(key: _privKeyStorageKey, value: privKey);
    await prefs.setString(_pubKeyStorageKey, pubKey);
  }

  static Future<String?> getPublicKey() async {
    final storage = await SharedPreferences.getInstance();
    return storage.getString(_pubKeyStorageKey);
  }
}
