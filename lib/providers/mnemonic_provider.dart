import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'mnemonic_provider.g.dart';

@riverpod
class MnemonicNotifier extends _$MnemonicNotifier {
  @override
  Future<String?> build() async {
    final storage = FlutterSecureStorage();
    final mnemonic = await storage.read(key: "mnemonic");

    return mnemonic;
  }

  Future<void> generateMnemonic() async {
    final mnemonic = Mnemonic.generate(Language.english, entropyLength: 128);
    await _saveMnemonic(mnemonic.sentence);
  }

  Future<void> importMnemonic(String mnemonic) async {
    List<String> words = mnemonic.split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      throw Exception("A frase de recuperação deve ter 12 ou 24 palavras.");
    }
    await _saveMnemonic(mnemonic);
  }

  Future<void> _saveMnemonic(String mnemonic) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: "mnemonic", value: mnemonic);

    state = AsyncValue.data(mnemonic);
  }
}
