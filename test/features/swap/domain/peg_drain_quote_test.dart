import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/peg_repository.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/peg_wallet.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_orchestrator.dart';

/// Regression cover for the drain peg-out quote returning zeros.
///
/// The failure: `PegOrchestrator.quote` prices the transaction against the
/// wallet's **own** address (no SideSwap order exists yet). `decodeTx` reports
/// *wallet-relative* net deltas, so for a drain self-send the output comes
/// straight back and the net L-BTC delta collapses to −fee. The old
/// `_drainOutputFromPset` computed `|delta| − fee`, i.e. zero — and that zero
/// propagated into the confirmation sheet as send=0, receive=0, service fee=0.
///
/// The wallet now resolves a drain from `balance − fee`, which is independent
/// of who the destination belongs to. These tests pin the consequences at the
/// orchestrator boundary.
void main() {
  late _FakeRepo repo;
  late _DrainWallet wallet;
  late _NoopStore store;
  late PegOrchestrator orchestrator;

  setUp(() {
    repo = _FakeRepo();
    wallet = _DrainWallet();
    store = _NoopStore();
    orchestrator = PegOrchestrator(
      repository: repo,
      wallet: wallet,
      store: store,
    );
  });

  group('drain peg-out quote', () {
    test('reports the real drained amount, not zero', () async {
      // Balance 200 000, LWK fee 26 → 199 974 reaches the deposit address.
      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegOut,
                amountSat: BigInt.zero,
                drain: true,
              )
              .run();

      final quote = result.getOrElse((e) => throw StateError('$e'));
      expect(
        quote.amountSat,
        BigInt.from(199974),
        reason: 'a drain quote that resolves to zero is the reported bug',
      );
      expect(quote.amountSat, isNot(BigInt.zero));
    });

    test('the SideSwap service fee is derived from the drained amount', () {
      // The fee is a percentage of what is actually sent. When the drained
      // amount collapsed to zero, 0.1% of zero rounded to zero — which is why
      // "SideSwap fees are not displayed" was a symptom of the same bug.
      const limits = PegServerLimits(
        minPegInSat: 10000,
        minPegOutSat: 25000,
        serverFeePercentPegIn: 0.1,
        serverFeePercentPegOut: 0.1,
      );

      expect(limits.serviceFeeSat(PegDirection.pegOut, 199974), 200);
      expect(
        limits.serviceFeeSat(PegDirection.pegOut, 0),
        0,
        reason: 'documents why a zero amount silently hid the fee row',
      );
    });

    test('estimated receive is the drained amount minus both fees', () async {
      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegOut,
                amountSat: BigInt.zero,
                drain: true,
              )
              .run();

      final quote = result.getOrElse((e) => throw StateError('$e'));
      // 199 974 − 26 network − 200 service (0.1%, rounded up) = 199 748
      expect(quote.networkFeeSat, BigInt.from(26));
      expect(quote.serviceFeeSat, BigInt.from(200));
      expect(quote.totalFeeSat, BigInt.from(226));
      expect(quote.estimatedReceiveSat, BigInt.from(199748));
    });

    test('a wallet that cannot resolve the drain surfaces an error, not a '
        'zero quote', () async {
      // The wallet returns a failure when the balance cannot cover the fee.
      // That must reach the sheet as an error so the amounts shimmer rather
      // than rendering a confident zero.
      wallet.failDrain = true;

      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegOut,
                amountSat: BigInt.zero,
                drain: true,
              )
              .run();

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<PegError>());
    });
  });

  group('fixed-amount peg-out quote', () {
    test('passes the requested amount straight through', () async {
      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegOut,
                amountSat: BigInt.from(50000),
              )
              .run();

      final quote = result.getOrElse((e) => throw StateError('$e'));
      expect(quote.amountSat, BigInt.from(50000));
      expect(quote.serviceFeeSat, BigInt.from(50));
    });
  });
}

class _FakeRepo implements PegRepository {
  @override
  TaskEither<PegError, PegServerLimits> getLimits() => TaskEither.right(
    const PegServerLimits(
      minPegInSat: 10000,
      minPegOutSat: 25000,
      serverFeePercentPegIn: 0.1,
      serverFeePercentPegOut: 0.1,
    ),
  );

  @override
  TaskEither<PegError, PegOrder> createOrder({
    required PegDirection direction,
    required String payoutAddress,
  }) => TaskEither.left(const PegProviderRejected('not used'));

  @override
  TaskEither<PegError, PegProgress> getStatus({
    required PegDirection direction,
    required String orderId,
  }) => TaskEither.left(PegOrderNotFound(orderId));
}

/// Models the fixed wallet: a drain resolves to `balance − fee` regardless of
/// whose address the destination is.
class _DrainWallet implements PegWallet {
  static final _balance = BigInt.from(200000);
  static final _fee = BigInt.from(26);
  bool failDrain = false;

  @override
  TaskEither<PegError, String> getLiquidPayoutAddress() =>
      TaskEither.right('lq1-own-address');

  @override
  TaskEither<PegError, String> getBitcoinPayoutAddress() =>
      TaskEither.right('bc1-own-address');

  @override
  TaskEither<PegError, PegFundingQuote> quoteLiquidFunding({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  }) {
    if (drain && failDrain) {
      return TaskEither.left(
        const PegWalletFailure('não foi possível calcular o valor do envio'),
      );
    }
    return TaskEither.right(
      PegFundingQuote(
        handle: 'pset',
        amountSat: drain ? _balance - _fee : amountSat,
        networkFeeSat: _fee,
      ),
    );
  }

  @override
  TaskEither<PegError, PegFundingQuote> quoteBitcoinFunding({
    required String destination,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) => TaskEither.right(
    PegFundingQuote(
      handle: 'psbt',
      amountSat: drain ? _balance - _fee : amountSat,
      networkFeeSat: _fee,
    ),
  );

  @override
  TaskEither<PegError, String> broadcastBitcoinFunding(PegFundingQuote quote) =>
      TaskEither.right('bdk-txid');

  @override
  TaskEither<PegError, String> broadcastLiquidFunding(PegFundingQuote quote) =>
      TaskEither.right('lwk-txid');
}

class _NoopStore implements PegStore {
  @override
  Future<void> recordCreated(
    PegOrder order, {
    required BigInt amountSat,
  }) async {}

  @override
  Future<void> recordFunded(String orderId, String fundingTxId) async {}

  @override
  Future<void> recordTerminal(
    String orderId, {
    required PegPhase phase,
    String? payoutTxId,
    String? errorMessage,
  }) async {}
}
