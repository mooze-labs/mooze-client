import 'package:drift/native.dart';
import 'package:mooze_mobile/database/database.dart';

/// Build an [AppDatabase] backed by [NativeDatabase.memory] for unit tests.
///
/// The migration strategy runs `onCreate`, so all tables and indexes are
/// present at v10. Each test should obtain its own instance and `close()`
/// it in tearDown to avoid cross-test state.
AppDatabase buildInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
