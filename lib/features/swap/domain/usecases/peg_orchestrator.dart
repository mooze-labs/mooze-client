import 'package:fpdart/fpdart.dart';

import '../entities/peg.dart';
import '../entities/peg_error.dart';
import '../repositories/peg_repository.dart';
import '../repositories/peg_wallet.dart';

abstract class PegStore {
  /// Record a created order **before** any funding broadcast.
  Future<void> recordCreated(PegOrder order, {required BigInt amountSat});

  /// Attach the funding txid once the broadcast returns.
  Future<void> recordFunded(String orderId, String fundingTxId);

  /// Move an order to a terminal state.
  Future<void> recordTerminal(
    String orderId, {
    required PegPhase phase,
    String? payoutTxId,
    String? errorMessage,
  });
}

/// What the user is shown before confirming a peg.
class PegQuote {
  const PegQuote({
    required this.direction,
    required this.amountSat,
    required this.networkFeeSat,
    required this.serviceFeeSat,
    required this.minimumSat,
  });

  final PegDirection direction;

  /// Gross amount the user is committing.
  final BigInt amountSat;

  /// On-chain fee for the funding transaction (BDK or LWK).
  final BigInt networkFeeSat;

  /// SideSwap's percentage cut.
  final BigInt serviceFeeSat;

  final BigInt minimumSat;

  BigInt get totalFeeSat => networkFeeSat + serviceFeeSat;

  BigInt get estimatedReceiveSat {
    final net = amountSat - totalFeeSat;
    return net > BigInt.zero ? net : BigInt.zero;
  }
}

/// Result of a successfully funded peg.
class PegExecution {
  const PegExecution({required this.order, required this.fundingTxId});
  final PegOrder order;
  final String fundingTxId;
}

class PegOrchestrator {
  PegOrchestrator({
    required PegRepository repository,
    required PegWallet wallet,
    required PegStore store,
  }) : _repository = repository,
       _wallet = wallet,
       _store = store;

  final PegRepository _repository;
  final PegWallet _wallet;
  final PegStore _store;

  TaskEither<PegError, PegQuote> quote({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    return _repository.getLimits().flatMap((limits) {
      final minimum = limits.minimumFor(direction);
      if (!drain && amountSat < BigInt.from(minimum)) {
        return TaskEither.left(
          PegBelowMinimum(minimumSat: minimum, actualSat: amountSat.toInt()),
        );
      }

      final placeholder =
          direction.isPegIn
              ? _wallet.getBitcoinPayoutAddress()
              : _wallet.getLiquidPayoutAddress();

      return placeholder.flatMap((address) {
        final funding =
            direction.isPegIn
                ? _wallet.quoteBitcoinFunding(
                  destination: address,
                  amountSat: amountSat,
                  feeRateSatPerVByte: feeRateSatPerVByte,
                  drain: drain,
                )
                : _wallet.quoteLiquidFunding(
                  destination: address,
                  amountSat: amountSat,
                  feeRateSatPerVb: feeRateSatPerVByte?.toDouble(),
                  drain: drain,
                );

        return funding.map(
          (q) => PegQuote(
            direction: direction,
            amountSat: q.amountSat,
            networkFeeSat: q.networkFeeSat,
            serviceFeeSat: BigInt.from(
              limits.serviceFeeSat(direction, q.amountSat.toInt()),
            ),
            minimumSat: BigInt.from(minimum),
          ),
        );
      });
    });
  }

  /// Create the order, fund it, and record every step.
  TaskEither<PegError, PegExecution> execute({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
    String? externalPayoutAddress,
  }) {
    return _resolvePayoutAddress(direction, externalPayoutAddress)
        .flatMap(
          (payoutAddress) => _repository.createOrder(
            direction: direction,
            payoutAddress: payoutAddress,
          ),
        )
        .flatMap(
          (order) => _persistThenFund(
            order: order,
            amountSat: amountSat,
            feeRateSatPerVByte: feeRateSatPerVByte,
            drain: drain,
          ),
        );
  }

  TaskEither<PegError, String> _resolvePayoutAddress(
    PegDirection direction,
    String? external,
  ) {
    if (external != null && external.trim().isNotEmpty) {
      if (direction.isPegIn) {
        return TaskEither.left(
          const PegWalletFailure(
            'peg-in deve receber em endereço da própria carteira',
          ),
        );
      }
      return TaskEither.right(external.trim());
    }
    return direction.isPegIn
        ? _wallet.getLiquidPayoutAddress()
        : _wallet.getBitcoinPayoutAddress();
  }

  TaskEither<PegError, PegExecution> _persistThenFund({
    required PegOrder order,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    required bool drain,
  }) {
    return TaskEither(() async {
      try {
        await _store.recordCreated(order, amountSat: amountSat);
      } catch (e) {
        return left(PegWalletFailure('falha ao registrar operação: $e'));
      }

      // (3) Build against the real deposit address.
      final quoteResult =
          await (order.direction.isPegIn
                  ? _wallet.quoteBitcoinFunding(
                    destination: order.depositAddress,
                    amountSat: amountSat,
                    feeRateSatPerVByte: feeRateSatPerVByte,
                    drain: drain,
                  )
                  : _wallet.quoteLiquidFunding(
                    destination: order.depositAddress,
                    amountSat: amountSat,
                    feeRateSatPerVb: feeRateSatPerVByte?.toDouble(),
                    drain: drain,
                  ))
              .run();

      final funding = quoteResult.toNullable();
      if (funding == null) {
        final failure = quoteResult.getLeft().getOrElse(
          () => const PegWalletFailure('falha ao montar a transação'),
        );
        // Nothing was broadcast, so this order is definitively dead.
        await _markFailed(order.orderId, failure);
        return left(failure);
      }

      final broadcastResult =
          await (order.direction.isPegIn
                  ? _wallet.broadcastBitcoinFunding(funding)
                  : _wallet.broadcastLiquidFunding(funding))
              .run();

      return broadcastResult.match(
        (error) {
          return _markFailed(
            order.orderId,
            error,
          ).then((_) => left<PegError, PegExecution>(error));
        },
        (txId) => _recordFunded(order.orderId, txId).then(
          (_) => right<PegError, PegExecution>(
            PegExecution(order: order, fundingTxId: txId),
          ),
        ),
      );
    });
  }

  Future<void> _markFailed(String orderId, PegError error) async {
    try {
      await _store.recordTerminal(
        orderId,
        phase: PegPhase.failed,
        errorMessage: error.message,
      );
    } catch (_) {
      // Best-effort: the caller already holds the error, and the row remains
      // as created, which is still recoverable.
    }
  }

  Future<void> _recordFunded(String orderId, String txId) async {
    try {
      await _store.recordFunded(orderId, txId);
    } catch (_) {
      // The broadcast succeeded; losing the txid annotation degrades
      // tracking but must never turn a sent transaction into a reported
      // failure. The tracker re-derives status from SideSwap regardless.
    }
  }
}
