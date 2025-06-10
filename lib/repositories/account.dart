import 'package:mooze_mobile/database.dart' as db;
import 'package:mooze_mobile/models/account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountRepository {
  final String _id;
  final AccountType _accountType;

  AccountRepository({required String id, required AccountType accountType})
    : _id = id,
      _accountType = accountType;

  String get id => _id;
  AccountType get accountType => _accountType;

  Future<String> fetchDescriptor() async {
    final appDb = db.AppDatabase();
    final account =
        await appDb.accounts.where((account) => account.id == _id).getSingle();
    return account.derivationPath;
  }

  Future<String?> fetchMnemonic() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'account_mnemonic_${_id}');
  }
}
