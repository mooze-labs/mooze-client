import 'package:mooze_mobile/models/account.dart';
import 'package:mooze_mobile/repositories/account.dart';

class AccountService {
  final AccountRepository _accountRepository;

  AccountService({required AccountRepository accountRepository})
    : _accountRepository = accountRepository;

  Future<List<Account>> getAllAcounts() async {
    // TODO: Implement this
    return [];
  }

  Future<Account> getAccount(String id) async {
    // TODO: Implement this
    return Account(id: '', accountType: AccountType.full);
  }

  Future<Account> createAccount(AccountType accountType) async {
    // TODO: Implement this
    return Account(id: '', accountType: accountType);
  }

  Future<void> deleteAccount(Account account) async {
    // TODO: Implement this
  }
}
