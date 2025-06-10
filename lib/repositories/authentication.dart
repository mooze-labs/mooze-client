import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mooze_mobile/repositories/wallet/mnemonic.dart';

class AuthenticationRepository {
  final String _walletId;

  AuthenticationRepository({required String walletId}) : _walletId = walletId;

  String get walletId => _walletId;

  Future<String> retrievePrivateKey() async {
    final storage = FlutterSecureStorage();
    final privateKey = await storage.read(
      key: 'account_private_key_${_walletId}',
    );

    if (privateKey == null) {
      throw Exception('Private key not found');
    }

    return privateKey;
  }
}
