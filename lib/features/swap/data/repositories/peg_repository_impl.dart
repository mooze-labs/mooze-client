import 'package:fpdart/fpdart.dart';

import '../../domain/entities/peg.dart';
import '../../domain/entities/peg_error.dart';
import '../../domain/repositories/peg_repository.dart';
import '../datasources/sideswap.dart';
import '../models.dart';

/// SideSwap-backed [PegRepository].
///
/// The only place that knows SideSwap's peg wire format. Everything above
/// consumes [PegOrder] / [PegProgress].
class PegRepositoryImpl implements PegRepository {
  PegRepositoryImpl({required SideswapService sideswapService})
    : _service = sideswapService;

  final SideswapService _service;

  @override
  TaskEither<PegError, PegServerLimits> getLimits() {
    return TaskEither.tryCatch(
      () async {
        final status = await _service.fetchServerStatus();
        return PegServerLimits(
          minPegInSat: status.minPegInAmount,
          minPegOutSat: status.minPegOutAmount,
          serverFeePercentPegIn: status.serverFeePercentPegIn,
          serverFeePercentPegOut: status.serverFeePercentPegOut,
        );
      },
      // A limits read is idempotent, so a timeout here is a plain transport
      // failure — nothing may have happened server-side.
      (e, _) => _readFailure(e),
    );
  }

  @override
  TaskEither<PegError, PegOrder> createOrder({
    required PegDirection direction,
    required String payoutAddress,
  }) {
    return TaskEither(() async {
      if (payoutAddress.trim().isEmpty) {
        return left(const PegWalletFailure('endereço de destino vazio'));
      }
      try {
        final response = await _service.createPegOrder(
          pegIn: direction.asPegInFlag,
          receiveAddress: payoutAddress,
        );
        return right(
          PegOrder(
            orderId: response.orderId,
            direction: direction,
            depositAddress: response.pegAddress,
            payoutAddress: payoutAddress,
            createdAt: response.createdAt,
            expiresAt: response.expiresAt,
          ),
        );
      } on SideswapRequestTimeout catch (e) {
        // A create is NOT idempotent: SideSwap may have registered the order
        // and lost the response. Retrying blind would strand a second order.
        return left(
          PegUnknownOutcome(stage: 'createOrder', detail: e.toString()),
        );
      } on SideswapRequestError catch (e) {
        return left(PegProviderRejected(e.message));
      } catch (e) {
        return left(PegTransportFailure(e.toString()));
      }
    });
  }

  @override
  TaskEither<PegError, PegProgress> getStatus({
    required PegDirection direction,
    required String orderId,
  }) {
    return TaskEither(() async {
      try {
        final status = await _service.fetchPegStatus(
          pegIn: direction.asPegInFlag,
          orderId: orderId,
        );
        return right(_toProgress(status, direction));
      } on SideswapRequestError catch (e) {
        // SideSwap reports an unknown order as a protocol error rather than
        // an empty result, so this is the not-found path.
        if (_looksLikeNotFound(e.message)) {
          return left(PegOrderNotFound(orderId));
        }
        return left(PegProviderRejected(e.message));
      } catch (e) {
        return left(_readFailure(e));
      }
    });
  }

  static bool _looksLikeNotFound(String message) {
    final m = message.toLowerCase();
    return m.contains('not found') ||
        m.contains('unknown order') ||
        m.contains('no such order');
  }

  static PegError _readFailure(Object e) {
    if (e is SideswapRequestError) return PegProviderRejected(e.message);
    return PegTransportFailure(e.toString());
  }

  PegProgress _toProgress(PegOrderStatus status, PegDirection direction) {
    final deposits = status.transactions
        .map(
          (tx) => PegDeposit(
            txId: tx.txHash,
            phase: _toPhase(tx.txState),
            amountSat: tx.amount,
            payoutSat: tx.payout,
            payoutTxId: tx.payoutTxid,
            detectedConfirmations: tx.detectedConfs,
            totalConfirmations: tx.totalConfs,
          ),
        )
        .toList(growable: false);

    return PegProgress(
      orderId: status.orderId,
      direction: direction,
      phase: aggregatePhase(deposits),
      deposits: deposits,
      depositAddress: status.address,
      payoutAddress: status.receiveAddress,
    );
  }

  /// Least-advanced deposit governs the order-level phase.
  ///
  /// An order funded by two payments where one has confirmed and the other
  /// has not is *not* complete, and reporting it as such would retire the
  /// tracker while money is still in flight.
  ///
  /// Exposed for tests — the aggregation rule is the part most likely to be
  /// silently wrong.
  static PegPhase aggregatePhase(List<PegDeposit> deposits) {
    if (deposits.isEmpty) return PegPhase.awaitingDeposit;
    return deposits
        .map((d) => d.phase)
        .reduce((a, b) => a.progressRank <= b.progressRank ? a : b);
  }

  static PegPhase _toPhase(TxState state) => switch (state) {
    TxState.insufficientAmount => PegPhase.insufficientAmount,
    TxState.detected => PegPhase.detected,
    TxState.processing => PegPhase.processing,
    TxState.done => PegPhase.completed,
    // An unrecognised state must not read as progress. Treating it as
    // "detected" keeps the tracker polling instead of retiring the order.
    TxState.unknown => PegPhase.detected,
  };
}
