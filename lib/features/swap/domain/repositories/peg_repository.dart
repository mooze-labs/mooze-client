import 'package:fpdart/fpdart.dart';

import '../entities/peg.dart';
import '../entities/peg_error.dart';

abstract class PegRepository {
  /// Minimums and fee percentages (`server_status`). No maximum exists.
  TaskEither<PegError, PegServerLimits> getLimits();

  TaskEither<PegError, PegOrder> createOrder({
    required PegDirection direction,
    required String payoutAddress,
  });

  /// One-shot status read for [orderId].
  TaskEither<PegError, PegProgress> getStatus({
    required PegDirection direction,
    required String orderId,
  });
}
