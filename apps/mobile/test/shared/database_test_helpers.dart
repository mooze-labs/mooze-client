import 'package:drift/native.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/data/services/wallet_id_service.dart';

/// Build an [AppDatabase] backed by [NativeDatabase.memory] for unit tests.
///
/// The migration strategy runs `onCreate`, so all tables and indexes are
/// present at the latest schema version. Each test should obtain its own
/// instance and `close()` it in tearDown to avoid cross-test state.
AppDatabase buildInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

/// In-memory WalletIdService that returns a deterministic id per instance.
/// Use a fresh instance per test for isolation; or share two instances
/// configured with different ids to simulate cross-wallet scoping.
class FakeWalletIdService implements WalletIdService {
  String _id;
  FakeWalletIdService([this._id = 'wallet-test']);

  @override
  Future<String> getOrCreate() async => _id;

  @override
  Future<void> clear() async {
    _id = 'wallet-test-cleared';
  }
}
