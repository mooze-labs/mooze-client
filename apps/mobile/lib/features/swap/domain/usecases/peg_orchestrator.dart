import 'package:fpdart/fpdart.dart';

import '../entities/peg.dart';
import '../entities/peg_error.dart';

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

  /// On-chain fee for the funding transaction.
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

/// Drives a peg from quote through funding.
abstract class PegOrchestrator {
  /// Minimums and fee percentages (`server_status`). No maximum exists.
  TaskEither<PegError, PegServerLimits> limits();

  /// Prices a peg without creating an order.
  TaskEither<PegError, PegQuote> quote({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  });

  /// Creates the order, records it, funds it from the wallet and starts
  /// tracking it. [externalPayoutAddress] is allowed only for peg-outs.
  TaskEither<PegError, PegExecution> execute({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
    String? externalPayoutAddress,
  });
}
