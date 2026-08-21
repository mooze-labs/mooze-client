import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/utils/peg_evidence.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

final pegEvidenceProvider = StreamProvider<PegEvidence>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final walletId = await ref.watch(walletIdProvider.future);

  String? lastSignature;

  await for (final rows in db.watchAllPegs(walletId: walletId)) {
    final signature = rows
        .map(
          (r) => '${r.orderId}|${r.pegIn}|${r.status}|'
              '${r.fundingTxId ?? ""}|${r.payoutTxId ?? ""}|'
              '${r.sideswapAddress}|${r.amount}',
        )
        .join(';');
    if (signature == lastSignature) continue;
    lastSignature = signature;

    yield PegEvidence(rows.map(_toRecord).toList(growable: false));
  }
});

PegRecord _toRecord(Peg row) => PegRecord(
  orderId: row.orderId,
  isPegIn: row.pegIn,
  amountSat: BigInt.from(row.amount),
  createdAt: row.createdAt,
  status: row.status,
  depositAddress: row.sideswapAddress,
  payoutAddress: row.payoutAddress,
  fundingTxId: row.fundingTxId,
  payoutTxId: row.payoutTxId,
);
