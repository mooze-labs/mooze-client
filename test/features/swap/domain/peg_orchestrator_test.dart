import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/peg_repository.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/peg_wallet.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_orchestrator.dart';

/// The orchestrator's ordering guarantees are what make a crashed peg
/// recoverable, so they are tested directly rather than inferred.
void main() {
  late _FakeRepo repo;
  late _FakeWallet wallet;
  late _RecordingStore store;
  late PegOrchestrator orchestrator;

  setUp(() {
    repo = _FakeRepo();
    wallet = _FakeWallet();
    store = _RecordingStore();
    orchestrator = PegOrchestrator(
      repository: repo,
      wallet: wallet,
      store: store,
    );
  });

  group('quote', () {
    test(
      'peg-out combines the LWK network fee with SideSwap\'s percentage',
      () async {
        // 0.1% of 100_000 = 100 sats service fee; LWK fee is the fake's 26.
        final result =
            await orchestrator
                .quote(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100000),
                )
                .run();

        final quote = result.getOrElse((e) => throw StateError('$e'));
        expect(quote.networkFeeSat, BigInt.from(26));
        expect(quote.serviceFeeSat, BigInt.from(100));
        expect(quote.totalFeeSat, BigInt.from(126));
        expect(quote.estimatedReceiveSat, BigInt.from(99874));
      },
    );

    test('peg-in quotes against the Bitcoin wallet', () async {
      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegIn,
                amountSat: BigInt.from(100000),
              )
              .run();

      expect(result.isRight(), isTrue);
      expect(wallet.bitcoinQuotes, 1);
      expect(wallet.liquidQuotes, 0);
    });

    test(
      'rejects below the published minimum without creating an order',
      () async {
        final result =
            await orchestrator
                .quote(
                  direction: PegDirection.pegIn,
                  amountSat: BigInt.from(100),
                )
                .run();

        final error = result.getLeft().toNullable();
        expect(error, isA<PegBelowMinimum>());
        expect((error as PegBelowMinimum).minimumSat, 1000);
        expect(repo.createdOrders, isEmpty);
      },
    );

    test('drain skips the minimum check', () async {
      final result =
          await orchestrator
              .quote(
                direction: PegDirection.pegOut,
                amountSat: BigInt.zero,
                drain: true,
              )
              .run();
      expect(result.isRight(), isTrue);
    });

    test('never creates an order — quoting must be free', () async {
      await orchestrator
          .quote(direction: PegDirection.pegOut, amountSat: BigInt.from(100000))
          .run();
      expect(repo.createdOrders, isEmpty);
    });

    test(
      'estimated receive floors at zero when fees exceed the amount',
      () async {
        repo.limits = const PegServerLimits(
          minPegInSat: 1,
          minPegOutSat: 1,
          serverFeePercentPegIn: 99,
          serverFeePercentPegOut: 99,
        );
        final result =
            await orchestrator
                .quote(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100),
                )
                .run();

        final quote = result.getOrElse((e) => throw StateError('$e'));
        expect(quote.estimatedReceiveSat, BigInt.zero);
      },
    );
  });

  group('execute — ordering', () {
    test('persists the order BEFORE broadcasting', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegOut,
            amountSat: BigInt.from(100000),
          )
          .run();

      expect(
        store.events,
        ['created:order-1', 'funded:order-1:lwk-txid'],
        reason: 'a broadcast recorded before the order would be unrecoverable',
      );
    });

    test('does not broadcast when persistence fails', () async {
      // If we cannot record the intent, sending would create an untracked
      // spend to an address we can no longer ask SideSwap about.
      store.failOnCreate = true;

      final result =
          await orchestrator
              .execute(
                direction: PegDirection.pegOut,
                amountSat: BigInt.from(100000),
              )
              .run();

      expect(result.isLeft(), isTrue);
      expect(wallet.liquidBroadcasts, 0);
    });

    test('peg-out funds through Liquid, never Bitcoin', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegOut,
            amountSat: BigInt.from(100000),
          )
          .run();

      expect(wallet.liquidBroadcasts, 1);
      expect(wallet.bitcoinBroadcasts, 0);
    });

    test('peg-in funds through Bitcoin, never Liquid', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegIn,
            amountSat: BigInt.from(100000),
          )
          .run();

      expect(wallet.bitcoinBroadcasts, 1);
      expect(wallet.liquidBroadcasts, 0);
    });

    test(
      'builds against the SideSwap deposit address, not the payout one',
      () async {
        await orchestrator
            .execute(
              direction: PegDirection.pegOut,
              amountSat: BigInt.from(100000),
            )
            .run();

        expect(wallet.lastLiquidDestination, 'sideswap-deposit-addr');
      },
    );
  });

  group('execute — failure handling', () {
    test(
      'a build failure marks the order failed and never broadcasts',
      () async {
        wallet.failLiquidQuoteOnDeposit = true;

        final result =
            await orchestrator
                .execute(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100000),
                )
                .run();

        expect(result.isLeft(), isTrue);
        expect(wallet.liquidBroadcasts, 0);
        expect(store.events, ['created:order-1', 'terminal:order-1:failed']);
      },
    );

    test(
      'a broadcast failure is recorded before the error is returned',
      () async {
        // Awaited rather than fire-and-forget: the UI reacts to this result
        // immediately, and a store that still says "pending" while the UI says
        // "failed" makes recovery ambiguous.
        wallet.failLiquidBroadcast = true;

        final result =
            await orchestrator
                .execute(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100000),
                )
                .run();

        expect(result.isLeft(), isTrue);
        expect(store.events, ['created:order-1', 'terminal:order-1:failed']);
      },
    );

    test(
      'a create timeout surfaces as PegUnknownOutcome, not a plain failure',
      () async {
        // SideSwap may have registered the order and lost the response — the
        // caller must reconcile, not retry.
        repo.createOutcome = const PegUnknownOutcome(
          stage: 'createOrder',
          detail: 'timeout',
        );

        final result =
            await orchestrator
                .execute(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100000),
                )
                .run();

        expect(result.getLeft().toNullable(), isA<PegUnknownOutcome>());
        expect(store.events, isEmpty);
        expect(wallet.liquidBroadcasts, 0);
      },
    );

    test(
      'a store failure after a successful broadcast still reports success',
      () async {
        // The coins moved. Reporting failure here would tell the user their
        // money is safe when it is already spent.
        store.failOnFunded = true;

        final result =
            await orchestrator
                .execute(
                  direction: PegDirection.pegOut,
                  amountSat: BigInt.from(100000),
                )
                .run();

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((e) => throw StateError('$e')).fundingTxId,
          'lwk-txid',
        );
      },
    );
  });

  group('execute — payout address', () {
    test('peg-out defaults to the wallet\'s own Bitcoin address', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegOut,
            amountSat: BigInt.from(100000),
          )
          .run();
      expect(repo.lastPayoutAddress, 'bc1-own');
    });

    test('peg-out accepts an external Bitcoin address', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegOut,
            amountSat: BigInt.from(100000),
            externalPayoutAddress: 'bc1-external',
          )
          .run();
      expect(repo.lastPayoutAddress, 'bc1-external');
    });

    test('peg-in refuses an external payout address', () async {
      // Peg-in proceeds must land where LWK holds the keys, otherwise they
      // are unspendable by this wallet.
      final result =
          await orchestrator
              .execute(
                direction: PegDirection.pegIn,
                amountSat: BigInt.from(100000),
                externalPayoutAddress: 'lq1-somebody-else',
              )
              .run();

      expect(result.getLeft().toNullable(), isA<PegWalletFailure>());
      expect(repo.createdOrders, isEmpty);
    });

    test('peg-in payout uses the LWK Liquid address', () async {
      await orchestrator
          .execute(
            direction: PegDirection.pegIn,
            amountSat: BigInt.from(100000),
          )
          .run();
      expect(repo.lastPayoutAddress, 'lq1-own');
    });
  });
}

class _FakeRepo implements PegRepository {
  PegServerLimits limits = const PegServerLimits(
    minPegInSat: 1000,
    minPegOutSat: 1000,
    serverFeePercentPegIn: 0.1,
    serverFeePercentPegOut: 0.1,
  );
  PegError? createOutcome;
  final List<String> createdOrders = [];
  String? lastPayoutAddress;

  @override
  TaskEither<PegError, PegServerLimits> getLimits() => TaskEither.right(limits);

  @override
  TaskEither<PegError, PegOrder> createOrder({
    required PegDirection direction,
    required String payoutAddress,
  }) {
    lastPayoutAddress = payoutAddress;
    final failure = createOutcome;
    if (failure != null) return TaskEither.left(failure);
    createdOrders.add('order-1');
    return TaskEither.right(
      PegOrder(
        orderId: 'order-1',
        direction: direction,
        depositAddress: 'sideswap-deposit-addr',
        payoutAddress: payoutAddress,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  TaskEither<PegError, PegProgress> getStatus({
    required PegDirection direction,
    required String orderId,
  }) => TaskEither.left(PegOrderNotFound(orderId));
}

class _FakeWallet implements PegWallet {
  int bitcoinQuotes = 0;
  int liquidQuotes = 0;
  int bitcoinBroadcasts = 0;
  int liquidBroadcasts = 0;
  String? lastLiquidDestination;
  bool failLiquidQuoteOnDeposit = false;
  bool failLiquidBroadcast = false;

  @override
  TaskEither<PegError, String> getLiquidPayoutAddress() =>
      TaskEither.right('lq1-own');

  @override
  TaskEither<PegError, String> getBitcoinPayoutAddress() =>
      TaskEither.right('bc1-own');

  @override
  TaskEither<PegError, PegFundingQuote> quoteBitcoinFunding({
    required String destination,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    bitcoinQuotes++;
    return TaskEither.right(
      PegFundingQuote(
        handle: 'psbt',
        amountSat: amountSat,
        networkFeeSat: BigInt.from(26),
      ),
    );
  }

  @override
  TaskEither<PegError, PegFundingQuote> quoteLiquidFunding({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  }) {
    liquidQuotes++;
    lastLiquidDestination = destination;
    if (failLiquidQuoteOnDeposit && destination == 'sideswap-deposit-addr') {
      return TaskEither.left(const PegInsufficientFunds('sem saldo'));
    }
    return TaskEither.right(
      PegFundingQuote(
        handle: 'pset',
        amountSat: amountSat,
        networkFeeSat: BigInt.from(26),
      ),
    );
  }

  @override
  TaskEither<PegError, String> broadcastBitcoinFunding(PegFundingQuote quote) {
    bitcoinBroadcasts++;
    return TaskEither.right('bdk-txid');
  }

  @override
  TaskEither<PegError, String> broadcastLiquidFunding(PegFundingQuote quote) {
    if (failLiquidBroadcast) {
      return TaskEither.left(const PegWalletFailure('relay rejeitou'));
    }
    liquidBroadcasts++;
    return TaskEither.right('lwk-txid');
  }
}

class _RecordingStore implements PegStore {
  final List<String> events = [];
  bool failOnCreate = false;
  bool failOnFunded = false;

  @override
  Future<void> recordCreated(
    PegOrder order, {
    required BigInt amountSat,
  }) async {
    if (failOnCreate) throw StateError('disk full');
    events.add('created:${order.orderId}');
  }

  @override
  Future<void> recordFunded(String orderId, String fundingTxId) async {
    if (failOnFunded) throw StateError('disk full');
    events.add('funded:$orderId:$fundingTxId');
  }

  @override
  Future<void> recordTerminal(
    String orderId, {
    required PegPhase phase,
    String? payoutTxId,
    String? errorMessage,
  }) async {
    events.add('terminal:$orderId:${phase.name}');
  }
}
