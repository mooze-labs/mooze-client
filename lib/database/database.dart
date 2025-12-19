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

class Deposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get depositId => text()();
  TextColumn get assetId => text()();
  IntColumn get amountInCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()();
  late final assetAmount = int64().nullable()();
  TextColumn get blockchainTxid => text().nullable()();
  TextColumn get pixKey => text()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  RealColumn get price => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Swaps, Pegs, Deposits, Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  // Get all swaps
  Future<List<Swap>> getAllSwaps() => select(swaps).get();

  // Get all pegs
  Future<List<Peg>> getAllPegs() => select(pegs).get();

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from <= 1 && to >= 2) {
          await m.createTable(deposits);
        }
        if (from <= 2 && to >= 3) {
          try {
            await m.addColumn(deposits, deposits.blockchainTxid);
          } catch (e) {
            // Column already exists, ignore the error
          }
        }
        if (from <= 3 && to >= 4) {
          await m.alterTable(
            TableMigration(
              deposits,
              columnTransformer: {deposits.status: Constant('pending')},
              newColumns: [deposits.status],
            ),
          );
        }
        if (from <= 4 && to >= 5) {
          await m.alterTable(
            TableMigration(
              deposits,
              columnTransformer: {deposits.pixKey: Constant("N/A")},
              newColumns: [deposits.pixKey],
            ),
          );
        }
        if (from <= 5 && to >= 6) {
          await m.createTable(products);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'mooze_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
