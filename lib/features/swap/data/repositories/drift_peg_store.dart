import 'package:drift/drift.dart' show Value;

import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';

import '../../domain/entities/peg.dart';
import '../../domain/usecases/peg_orchestrator.dart';
import '../../domain/usecases/peg_tracker.dart';

class DriftPegStore implements PegStore, PegRecoverySource {
  DriftPegStore({
    required AppDatabase database,
    required String walletId,
    SwapAuditRepository? audit,
  }) : _db = database,
       _walletId = walletId,
       _audit = audit;

  final AppDatabase _db;
  final String _walletId;
  final SwapAuditRepository? _audit;

  @override
  Future<void> recordCreated(
    PegOrder order, {
    required BigInt amountSat,
  }) async {
    // Idempotent: a create that timed out and was later reconciled must not
    // produce a second row for the same SideSwap order.
    final existing = await _db.findPegByOrderId(
      orderId: order.orderId,
      walletId: _walletId,
    );
    if (existing != null) return;

    await _db.insertPeg(
      PegsCompanion.insert(
        orderId: order.orderId,
        pegIn: order.direction.isPegIn,
        sideswapAddress: order.depositAddress,
        payoutAddress: order.payoutAddress,
        amount: amountSat.toInt(),
        walletId: Value(_walletId),
        status: const Value(pegStatusPending),
        provider: const Value('sideswap'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _recordAudit(order, amountSat);
  }

  @override
  Future<void> recordFunded(String orderId, String fundingTxId) async {
    await _db.updatePegProgress(
      orderId: orderId,
      walletId: _walletId,
      fundingTxId: fundingTxId,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> recordTerminal(
    String orderId, {
    required PegPhase phase,
    String? payoutTxId,
    String? errorMessage,
  }) async {
    await _db.updatePegProgress(
      orderId: orderId,
      walletId: _walletId,
      status: _statusFor(phase),
      payoutTxId: payoutTxId,
      errorMessage: errorMessage,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TrackedPeg>> loadActivePegs() async {
    final rows = await _db.getActivePegs(walletId: _walletId);
    return rows
        .map(
          (row) => TrackedPeg(
            orderId: row.orderId,
            direction: row.pegIn ? PegDirection.pegIn : PegDirection.pegOut,
            phase:
                row.fundingTxId == null
                    ? PegPhase.awaitingDeposit
                    : PegPhase.detected,
            amountSat: BigInt.from(row.amount),
            depositAddress: row.sideswapAddress,
            fundingTxId: row.fundingTxId,
            payoutTxId: row.payoutTxId,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _recordAudit(PegOrder order, BigInt amountSat) async {
    final audit = _audit;
    if (audit == null) return;
    try {
      await audit.recordPending(
        provider: 'sideswap',
        direction: order.direction.auditDirection,
        sendAsset: order.direction.isPegIn ? 'BTC' : 'LBTC',
        receiveAsset: order.direction.isPegIn ? 'LBTC' : 'BTC',
        sendAmount: amountSat,
        receiveAmount: amountSat,
        metadata: {
          'orderId': order.orderId,
          'depositAddress': order.depositAddress,
          'payoutAddress': order.payoutAddress,
        },
      );
    } catch (_) {
      // History annotation is never worth failing a peg over.
    }
  }

  static String _statusFor(PegPhase phase) => switch (phase) {
    PegPhase.completed => pegStatusCompleted,
    PegPhase.insufficientAmount => pegStatusInsufficientAmount,
    PegPhase.failed => pegStatusFailed,
    _ => pegStatusPending,
  };
}
