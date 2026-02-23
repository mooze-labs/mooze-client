import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/database/database.dart';

class PixDepositDatabase {
  final AppDatabase _database;

  PixDepositDatabase(AppDatabase database) : _database = database;

  TaskEither<String, Unit> addNewDeposit(
    String depositId,
    String pixKey,
    String assetId,
    int amountInCents,
  ) {
    return TaskEither.tryCatch(() async {
      await _database
          .into(_database.deposits)
          .insert(
            DepositsCompanion.insert(
              depositId: depositId,
              pixKey: pixKey,
              assetId: assetId,
              amountInCents: amountInCents,
              status: "pending",
            ),
          );

      return unit;
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, Unit> updateDepositStatus(
    String depositId,
    String status,
  ) {
    return TaskEither.tryCatch(() async {
      await (_database.update(_database.deposits)..where(
        (tbl) => tbl.depositId.equals(depositId),
      )).write(DepositsCompanion(status: Value(status)));

      return unit;
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, Unit> updateDeposit(
    String depositId,
    String status, {
    BigInt? assetAmount,
    String? blockchainTxid,
  }) {
    return TaskEither.tryCatch(() async {
      await (_database.update(_database.deposits)
        ..where((tbl) => tbl.depositId.equals(depositId))).write(
        DepositsCompanion(
          status: Value(status),
          assetAmount:
              assetAmount != null ? Value(assetAmount) : Value.absent(),
          blockchainTxid:
              blockchainTxid != null ? Value(blockchainTxid) : Value.absent(),
        ),
      );

      return unit;
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, Unit> markDepositAsCompleted(
    String depositId,
    BigInt assetAmount,
    String blockchainTxid,
  ) {
    return TaskEither.tryCatch(() async {
      await (_database.update(_database.deposits)
        ..where((tbl) => tbl.depositId.equals(depositId))).write(
        DepositsCompanion(
          assetAmount: Value(assetAmount),
          blockchainTxid: Value(blockchainTxid),
        ),
      );

      return unit;
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, Option<Deposit>> getDeposit(String depositId) {
    return TaskEither.tryCatch(
      () async {
        return await (_database.select(_database.deposits)
          ..where((tbl) => tbl.depositId.equals(depositId))).getSingleOrNull();
      },
      (error, stackTrace) => error.toString(),
    ).map((d) => Option.fromNullable(d));
  }

  TaskEither<String, List<Deposit>> getDeposits({int? limit, int? offset}) {
    return TaskEither.tryCatch(() async {
      final query = (_database.select(_database.deposits));
      query.orderBy([(d) => OrderingTerm.desc(d.createdAt)]);

      if (limit != null) {
        query.limit(limit, offset: offset);
      }

      return await (query.get());
    }, (error, stackTrace) => error.toString());
  }
}
