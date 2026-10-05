import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/swap/data/repositories/core_peg_orchestrator.dart';
import 'package:mooze_mobile/features/swap/data/services/core_sideswap_session.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';

class _MockCore extends Mock implements MoozeCore {}

class _MockAudit extends Mock implements SwapAuditRepository {}

PegExecutionDto _execution(PegDirectionDto direction) => PegExecutionDto(
      order: PegOrderDto(
        orderId: 'order-1',
        direction: direction,
        depositAddress: 'deposit-addr',
        payoutAddress: 'payout-addr',
        createdAtMs: BigInt.from(1700000000000),
      ),
      fundingTxId: 'funding-tx',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(PegDirectionDto.pegIn);
  });

  late _MockCore core;
  late _MockAudit audit;
  late LiquidSpendCoordinator coordinator;
  late CorePegOrchestrator orchestrator;

  void stubExecute(PegDirectionDto direction) => when(
        () => core.pegExecute(
          walletId: any(named: 'walletId'),
          direction: any(named: 'direction'),
          amountSat: any(named: 'amountSat'),
          feeRateSatPerVbyte: any(named: 'feeRateSatPerVbyte'),
          drain: any(named: 'drain'),
          externalPayoutAddress: any(named: 'externalPayoutAddress'),
        ),
      ).thenAnswer((_) async => _execution(direction));

  setUp(() {
    core = _MockCore();
    audit = _MockAudit();
    coordinator = LiquidSpendCoordinator(
      acquireTimeout: const Duration(seconds: 5),
    );
    when(() => core.sideswapConnect(
          apiKey: any(named: 'apiKey'),
          url: any(named: 'url'),
        )).thenAnswer((_) async {});
    when(
      () => audit.recordPending(
        provider: any(named: 'provider'),
        direction: any(named: 'direction'),
        sendAsset: any(named: 'sendAsset'),
        receiveAsset: any(named: 'receiveAsset'),
        sendAmount: any(named: 'sendAmount'),
        receiveAmount: any(named: 'receiveAmount'),
        txId: any(named: 'txId'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async => right(1));
    orchestrator = CorePegOrchestrator(
      session: CoreSideswapSession(core: Future.value(core), apiKey: 'key'),
      walletId: Future.value('wallet-1'),
      audit: audit,
      coordinator: coordinator,
    );
  });

  test('limits maps the core minimums and fees', () async {
    when(() => core.pegLimits()).thenAnswer(
      (_) async => PegServerLimitsDto(
        minPegInSat: BigInt.from(10000),
        minPegOutSat: BigInt.from(25000),
        serverFeePercentPegIn: 0.1,
        serverFeePercentPegOut: 0.1,
      ),
    );

    final limits =
        (await orchestrator.limits().run()).getRight().toNullable()!;

    expect(limits.minimumFor(PegDirection.pegIn), 10000);
    expect(limits.minimumFor(PegDirection.pegOut), 25000);
  });

  test('quote passes the request and maps the fees', () async {
    when(
      () => core.pegQuote(
        direction: PegDirectionDto.pegOut,
        amountSat: BigInt.from(100000),
        feeRateSatPerVbyte: 2,
        drain: true,
      ),
    ).thenAnswer(
      (_) async => PegQuoteDto(
        direction: PegDirectionDto.pegOut,
        amountSat: BigInt.from(99000),
        networkFeeSat: BigInt.from(300),
        serviceFeeSat: BigInt.from(99),
        minimumSat: BigInt.from(25000),
        totalFeeSat: BigInt.from(399),
        estimatedReceiveSat: BigInt.from(98601),
      ),
    );

    final quote = (await orchestrator
            .quote(
              direction: PegDirection.pegOut,
              amountSat: BigInt.from(100000),
              feeRateSatPerVByte: 2,
              drain: true,
            )
            .run())
        .getRight()
        .toNullable()!;

    expect(quote.amountSat, BigInt.from(99000));
    expect(quote.totalFeeSat, BigInt.from(399));
    expect(quote.estimatedReceiveSat, BigInt.from(98601));
  });

  group('execute', () {
    test('passes the wallet id and records the audit row', () async {
      stubExecute(PegDirectionDto.pegIn);

      final execution = (await orchestrator
              .execute(
                direction: PegDirection.pegIn,
                amountSat: BigInt.from(50000),
                feeRateSatPerVByte: 5,
              )
              .run())
          .getRight()
          .toNullable()!;

      expect(execution.order.orderId, 'order-1');
      expect(execution.order.depositAddress, 'deposit-addr');
      expect(execution.fundingTxId, 'funding-tx');
      verify(
        () => core.pegExecute(
          walletId: 'wallet-1',
          direction: PegDirectionDto.pegIn,
          amountSat: BigInt.from(50000),
          feeRateSatPerVbyte: 5,
          drain: false,
          externalPayoutAddress: null,
        ),
      ).called(1);
      verify(
        () => audit.recordPending(
          provider: 'sideswap',
          direction: 'btc_to_lbtc',
          sendAsset: 'BTC',
          receiveAsset: 'LBTC',
          sendAmount: BigInt.from(50000),
          receiveAmount: BigInt.from(50000),
          metadata: {
            'orderId': 'order-1',
            'depositAddress': 'deposit-addr',
            'payoutAddress': 'payout-addr',
          },
        ),
      ).called(1);
    });

    test('peg-out accepts a trimmed external Bitcoin address', () async {
      stubExecute(PegDirectionDto.pegOut);

      await orchestrator
          .execute(
            direction: PegDirection.pegOut,
            amountSat: BigInt.from(50000),
            externalPayoutAddress: '  bc1qexternal  ',
          )
          .run();

      verify(
        () => core.pegExecute(
          walletId: 'wallet-1',
          direction: PegDirectionDto.pegOut,
          amountSat: BigInt.from(50000),
          feeRateSatPerVbyte: null,
          drain: false,
          externalPayoutAddress: 'bc1qexternal',
        ),
      ).called(1);
    });

    test('peg-in refuses an external payout address', () async {
      final result = await orchestrator
          .execute(
            direction: PegDirection.pegIn,
            amountSat: BigInt.from(50000),
            externalPayoutAddress: 'bc1qexternal',
          )
          .run();

      expect(result.getLeft().toNullable(), isA<PegWalletFailure>());
      verifyNever(
        () => core.pegExecute(
          walletId: any(named: 'walletId'),
          direction: any(named: 'direction'),
          amountSat: any(named: 'amountSat'),
          feeRateSatPerVbyte: any(named: 'feeRateSatPerVbyte'),
          drain: any(named: 'drain'),
          externalPayoutAddress: any(named: 'externalPayoutAddress'),
        ),
      );
    });

    test('peg-out waits for the shared Liquid spend lock', () async {
      stubExecute(PegDirectionDto.pegOut);
      final release = Completer<void>();
      final holder = coordinator.protect('other-spend', () => release.future);

      final pending = orchestrator
          .execute(direction: PegDirection.pegOut, amountSat: BigInt.from(1))
          .run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      verifyNever(
        () => core.pegExecute(
          walletId: any(named: 'walletId'),
          direction: any(named: 'direction'),
          amountSat: any(named: 'amountSat'),
          feeRateSatPerVbyte: any(named: 'feeRateSatPerVbyte'),
          drain: any(named: 'drain'),
          externalPayoutAddress: any(named: 'externalPayoutAddress'),
        ),
      );

      release.complete();
      await holder;
      final result = await pending;

      expect(result.isRight(), isTrue);
    });

    test('an audit failure does not fail a funded peg', () async {
      stubExecute(PegDirectionDto.pegIn);
      when(
        () => audit.recordPending(
          provider: any(named: 'provider'),
          direction: any(named: 'direction'),
          sendAsset: any(named: 'sendAsset'),
          receiveAsset: any(named: 'receiveAsset'),
          sendAmount: any(named: 'sendAmount'),
          receiveAmount: any(named: 'receiveAmount'),
          txId: any(named: 'txId'),
          metadata: any(named: 'metadata'),
        ),
      ).thenThrow(StateError('db closed'));

      final result = await orchestrator
          .execute(direction: PegDirection.pegIn, amountSat: BigInt.from(1))
          .run();

      expect(result.isRight(), isTrue);
    });
  });

  group('error mapping', () {
    test('a core timeout is an unknown outcome', () {
      final error = pegErrorFromCore(
        const CoreError(kind: CoreErrorKind.timeout, message: 'sem resposta'),
      );
      expect(error, isA<PegUnknownOutcome>());
    });

    test('other core errors keep the core text', () {
      final error = pegErrorFromCore(
        const CoreError(
          kind: CoreErrorKind.invalidInput,
          message: 'Valor mínimo é 25000 sats',
        ),
      );
      expect(error, isA<PegCoreFailure>());
      expect(error.message, 'Valor mínimo é 25000 sats');
    });

    test('a failed execute returns the mapped error', () async {
      when(
        () => core.pegExecute(
          walletId: any(named: 'walletId'),
          direction: any(named: 'direction'),
          amountSat: any(named: 'amountSat'),
          feeRateSatPerVbyte: any(named: 'feeRateSatPerVbyte'),
          drain: any(named: 'drain'),
          externalPayoutAddress: any(named: 'externalPayoutAddress'),
        ),
      ).thenThrow(
        const CoreError(
          kind: CoreErrorKind.service,
          message: 'SideSwap recusou a operação: x',
        ),
      );

      final result = await orchestrator
          .execute(direction: PegDirection.pegIn, amountSat: BigInt.from(1))
          .run();

      expect(
        result.getLeft().toNullable()!.message,
        'SideSwap recusou a operação: x',
      );
      verifyNever(
        () => audit.recordPending(
          provider: any(named: 'provider'),
          direction: any(named: 'direction'),
          sendAsset: any(named: 'sendAsset'),
          receiveAsset: any(named: 'receiveAsset'),
          sendAmount: any(named: 'sendAmount'),
          receiveAmount: any(named: 'receiveAmount'),
          txId: any(named: 'txId'),
          metadata: any(named: 'metadata'),
        ),
      );
    });
  });
}
