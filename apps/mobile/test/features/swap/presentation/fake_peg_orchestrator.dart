import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_orchestrator.dart';

/// The limits of the SideSwap fixtures: 10 000 sats for a peg-in, 25 000
/// for a peg-out.
const testPegLimits = PegServerLimits(
  minPegInSat: 10000,
  minPegOutSat: 25000,
  serverFeePercentPegIn: 0.1,
  serverFeePercentPegOut: 0.1,
);

/// A [PegOrchestrator] with the rules of mooze-core: a drain sends the
/// balance less the network fee, and an amount below the minimum is refused.
class FakePegOrchestrator implements PegOrchestrator {
  FakePegOrchestrator({
    this.limitsValue = testPegLimits,
    this.bitcoinBalanceSat = 67234,
    this.liquidBalanceSat = 1015,
  });

  final PegServerLimits limitsValue;
  final int bitcoinBalanceSat;
  final int liquidBalanceSat;

  /// The quotes asked for, in order.
  final List<
    ({
      PegDirection direction,
      BigInt amountSat,
      bool drain,
      int? feeRateSatPerVByte,
    })
  >
  quotes = [];

  /// Orders the app tried to create and fund.
  int executions = 0;

  /// When set, each quote waits for the next completer before it answers.
  final List<Completer<void>> holds = [];

  /// The network fee when no fee rate is given.
  static const int networkFeeSat = 20;

  /// The size of the funding transaction: a fee rate of 2 sat/vB costs 200.
  static const int fundingVsize = 100;

  @override
  TaskEither<PegError, PegServerLimits> limits() =>
      TaskEither.right(limitsValue);

  Either<PegError, PegQuote> _price(
    PegDirection direction,
    BigInt amountSat,
    bool drain,
    int? feeRateSatPerVByte,
  ) {
    final networkFeeSat = feeRateSatPerVByte == null
        ? FakePegOrchestrator.networkFeeSat
        : feeRateSatPerVByte * fundingVsize;
    final balance = direction.isPegIn ? bitcoinBalanceSat : liquidBalanceSat;
    final amount = drain ? balance - networkFeeSat : amountSat.toInt();
    final minimum = limitsValue.minimumFor(direction);
    if (amount < minimum) {
      return Left(PegBelowMinimum(minimumSat: minimum, actualSat: amount));
    }
    return Right(
      PegQuote(
        direction: direction,
        amountSat: BigInt.from(amount),
        networkFeeSat: BigInt.from(networkFeeSat),
        serviceFeeSat: BigInt.from((amount * 0.001).ceil()),
        minimumSat: BigInt.from(minimum),
      ),
    );
  }

  @override
  TaskEither<PegError, PegQuote> quote({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    quotes.add((
      direction: direction,
      amountSat: amountSat,
      drain: drain,
      feeRateSatPerVByte: feeRateSatPerVByte,
    ));
    final hold = holds.isEmpty ? null : holds.removeAt(0);
    return TaskEither(() async {
      await hold?.future;
      return _price(direction, amountSat, drain, feeRateSatPerVByte);
    });
  }

  @override
  TaskEither<PegError, PegExecution> execute({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
    String? externalPayoutAddress,
  }) {
    executions++;
    return TaskEither.left(const PegProviderRejected('not in tests'));
  }
}
