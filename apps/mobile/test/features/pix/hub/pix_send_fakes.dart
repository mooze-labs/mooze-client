import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' show depixAssetId;

/// Test doubles of the Pix send flow: the withdrawal API, the wallet and the
/// poll timer.

final DateTime testStart = DateTime.utc(2026, 10, 24, 12);

/// A withdrawal as the backend creates it for [payout].
PixWithdrawal testWithdrawal({
  int payout = 4590,
  int fee = 99,
  String id = 'w-1',
  Duration validFor = const Duration(minutes: 30),
  DateTime? now,
}) {
  final deadline = (now ?? testStart).add(validFor);
  return PixWithdrawal(
    id: id,
    providerId: 'eulen-$id',
    depositAddress: 'lq1qqdeposit$id',
    assetId: depixAssetId,
    depositAmountInCents: payout + fee,
    depositAmountSats: (payout + fee) * PixWithdrawal.depixUnitsPerCent,
    payoutAmountInCents: payout,
    expiresAt: deadline,
    fundingDeadline: deadline,
  );
}

PixWithdrawalDetails testDetails(String id, PixWithdrawalStatus status) =>
    PixWithdrawalDetails(id: id, status: status, createdAt: testStart);

class FakeWithdrawalRepository implements PixWithdrawalRepository {
  final List<Map<String, Object>> creates = [];
  final List<List<String>> statusReads = [];

  /// Answer of `create`, built from the requested payout.
  Either<PixHubFailure, PixWithdrawal> Function(int payout) onCreate =
      (payout) => Right(testWithdrawal(payout: payout));

  /// Answers of `statuses`, one per call. An empty queue answers no items.
  final List<Either<PixHubFailure, List<PixWithdrawalDetails>>> statusAnswers =
      [];

  @override
  TaskEither<PixHubFailure, PixWithdrawal> create({
    required String pixKey,
    required int payoutAmountInCents,
    required String taxId,
    required String refundAddress,
  }) {
    creates.add({
      'pix_key': pixKey,
      'payout': payoutAmountInCents,
      'tax_id': taxId,
      'refund_address': refundAddress,
    });
    return TaskEither.fromEither(onCreate(payoutAmountInCents));
  }

  @override
  TaskEither<PixHubFailure, List<PixWithdrawalDetails>> statuses(
    List<String> ids,
  ) {
    statusReads.add(ids);
    return TaskEither.fromEither(
      statusAnswers.isEmpty ? const Right([]) : statusAnswers.removeAt(0),
    );
  }
}

class FakeWithdrawalWallet implements PixWithdrawalWallet {
  /// 10,000 DePix.
  int balance = 10000 * 100 * PixWithdrawal.depixUnitsPerCent;

  final List<(String, int)> estimates = [];
  final List<(String, int)> sends = [];

  Either<PixHubFailure, int> Function(String address, int amount) onEstimate =
      (_, _) => const Right(152);

  /// Answer of `send`. Set [sendGate] to hold the answer until the test
  /// completes it.
  PixFundingResult sendResult = const PixFundingSent(txid: 'txid-1');
  Completer<PixFundingResult>? sendGate;

  /// Runs inside `send`, before it answers.
  void Function()? onSend;

  @override
  Future<Either<PixHubFailure, String>> refundAddress() async =>
      const Right('lq1qqrefund');

  @override
  Future<Either<PixHubFailure, int>> depixBalanceSats() async => Right(balance);

  @override
  Future<Either<PixHubFailure, int>> estimateNetworkFeeSats({
    required String address,
    required int amountSats,
  }) async {
    estimates.add((address, amountSats));
    return onEstimate(address, amountSats);
  }

  @override
  Future<PixFundingResult> send({
    required String address,
    required int amountSats,
  }) async {
    sends.add((address, amountSats));
    onSend?.call();
    final gate = sendGate;
    return gate == null ? sendResult : gate.future;
  }
}

class FakeTimer implements Timer {
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}
