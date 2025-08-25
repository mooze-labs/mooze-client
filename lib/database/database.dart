import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'database.steps.dart';

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

@DriftDatabase(tables: [Swaps, Pegs, Deposits])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  // Get all swaps
  Future<List<Swap>> getAllSwaps() => select(swaps).get();

  // Get all pegs
  Future<List<Peg>> getAllPegs() => select(pegs).get();

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.createTable(schema.deposits);
        },
        from2To3: (m, schema) async {
          await m.addColumn(deposits, deposits.blockchainTxid);
        },
        from3To4: (m, schema) async {
          await m.alterTable(
              TableMigration(deposits, columnTransformer: {
                deposits.status: Constant('pending')
              },
              newColumns: [deposits.status]
              )
          );
        },
        from4To5: (m, schema) async {
          await m.alterTable(TableMigration(deposits, columnTransformer: {deposits.pixKey: Constant("N/A")}, newColumns: [deposits.pixKey]));
        }
      ),
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
