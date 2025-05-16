import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Swaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sendAsset => text().withLength(min: 64, max: 64)();
  TextColumn get receiveAsset => text().withLength(min: 64, max: 64)();
  IntColumn get sendAmount => integer()();
  IntColumn get receiveAmount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Pegs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  BoolColumn get pegIn => boolean()();
  TextColumn get sideswapAddress => text()();
  TextColumn get payoutAddress => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Swaps, Pegs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Get all swaps
  Future<List<Swap>> getAllSwaps() => select(swaps).get();

  // Get all pegs
  Future<List<Peg>> getAllPegs() => select(pegs).get();

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'mooze_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
