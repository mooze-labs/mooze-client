import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_amount_validation.dart';

/// The amount-validation decision table for the BTC ⇄ L-BTC swap screen.
///
/// Covers every scenario in the migration checklist, in both directions.
/// Limits are the real values SideSwap publishes (verified live 2026-08-08):
/// 10 000 sats peg-in, 25 000 peg-out, 0.1 % either way.
void main() {
  const limits = PegServerLimits(
    minPegInSat: 10000,
    minPegOutSat: 25000,
    serverFeePercentPegIn: 0.1,
    serverFeePercentPegOut: 0.1,
  );

  final fallback = BigInt.from(25000);

  PegAmountValidation check({
    required PegDirection direction,
    int? amount,
    required int balance,
    PegServerLimits? withLimits = limits,
    bool drain = false,
  }) => evaluatePegAmount(
    direction: direction,
    amountSat: amount == null ? null : BigInt.from(amount),
    spendableSat: BigInt.from(balance),
    limits: withLimits,
    fallbackMinimumSats: fallback,
    drain: drain,
  );

  group('BTC → L-BTC (peg-in)', () {
    test('valid amount passes and reports both bounds', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 50000,
        balance: 200000,
      );

      expect(r.isValid, isTrue);
      expect(r.issue, isNull);
      expect(r.minimumSats, BigInt.from(10000));
      expect(r.maximumSats, BigInt.from(200000));
      expect(r.showsIssue, isFalse);
    });

    test('below the 10 000 sat minimum is rejected', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 9999,
        balance: 200000,
      );

      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.belowMinimum);
      expect(r.showsIssue, isTrue);
      expect(r.minimumSats, BigInt.from(10000));
    });

    test('exactly the minimum is accepted', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 10000,
        balance: 200000,
      );
      expect(r.isValid, isTrue);
    });

    test('12 000 sats is valid for peg-in — the old hardcoded 25 000 floor '
        'wrongly blocked this', () {
      // Regression guard for the bug this migration fixed: the screen applied
      // a single 25 000 floor to both directions, silently blocking valid
      // 10–25k peg-ins.
      final r = check(
        direction: PegDirection.pegIn,
        amount: 12000,
        balance: 200000,
      );
      expect(r.isValid, isTrue);
    });

    test('above the spendable balance is rejected as the maximum', () {
      // SideSwap publishes no maximum, so the balance is the ceiling.
      final r = check(
        direction: PegDirection.pegIn,
        amount: 200001,
        balance: 200000,
      );

      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.aboveBalance);
      expect(r.maximumSats, BigInt.from(200000));
    });

    test('exactly the balance is accepted', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 200000,
        balance: 200000,
      );
      expect(r.isValid, isTrue);
    });

    test('insufficient balance: amount above a balance below the minimum', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 50000,
        balance: 1000,
      );
      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.aboveBalance);
    });
  });

  group('L-BTC → BTC (peg-out)', () {
    test('valid amount passes with the peg-out minimum', () {
      final r = check(
        direction: PegDirection.pegOut,
        amount: 50000,
        balance: 200000,
      );

      expect(r.isValid, isTrue);
      expect(r.minimumSats, BigInt.from(25000));
    });

    test('below the 25 000 sat minimum is rejected', () {
      final r = check(
        direction: PegDirection.pegOut,
        amount: 24999,
        balance: 200000,
      );

      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.belowMinimum);
      expect(r.minimumSats, BigInt.from(25000));
    });

    test('12 000 sats is rejected for peg-out but valid for peg-in', () {
      // The two directions genuinely differ — the whole point of reading
      // limits per direction instead of using one constant.
      expect(
        check(
          direction: PegDirection.pegOut,
          amount: 12000,
          balance: 200000,
        ).isValid,
        isFalse,
      );
      expect(
        check(
          direction: PegDirection.pegIn,
          amount: 12000,
          balance: 200000,
        ).isValid,
        isTrue,
      );
    });

    test('above the spendable balance is rejected', () {
      final r = check(
        direction: PegDirection.pegOut,
        amount: 300000,
        balance: 200000,
      );
      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.aboveBalance);
    });
  });

  group('empty and neutral states', () {
    test('no amount is neutral — not valid, but shows no error', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: null,
        balance: 200000,
      );

      expect(r.hasAmount, isFalse);
      expect(r.isValid, isFalse);
      expect(
        r.showsIssue,
        isFalse,
        reason: 'an untouched field must not display an error',
      );
    });

    test('zero is treated as no amount', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 0,
        balance: 200000,
      );
      expect(r.showsIssue, isFalse);
      expect(r.isValid, isFalse);
    });
  });

  group('drain', () {
    test('drain is valid regardless of the typed amount', () {
      // Drain spends the whole balance; gating on a not-yet-known amount
      // would disable a legitimate action.
      final r = check(
        direction: PegDirection.pegOut,
        amount: null,
        balance: 200000,
        drain: true,
      );
      expect(r.isValid, isTrue);
      expect(r.maximumSats, BigInt.from(200000));
    });

    test('drain ignores an amount below the minimum', () {
      final r = check(
        direction: PegDirection.pegOut,
        amount: 1,
        balance: 200000,
        drain: true,
      );
      expect(r.isValid, isTrue);
    });
  });

  group('degraded limits', () {
    test('falls back to the conservative floor when server_status is '
        'unreachable', () {
      // Must not block the flow entirely: fall back to 25 000 rather than
      // failing closed on an unavailable status call.
      final r = check(
        direction: PegDirection.pegIn,
        amount: 12000,
        balance: 200000,
        withLimits: null,
      );

      expect(r.isValid, isFalse);
      expect(r.issue, PegAmountIssue.belowMinimum);
      expect(r.minimumSats, BigInt.from(25000));
    });

    test('a valid amount still passes without live limits', () {
      final r = check(
        direction: PegDirection.pegIn,
        amount: 50000,
        balance: 200000,
        withLimits: null,
      );
      expect(r.isValid, isTrue);
    });
  });

  group('rule ordering', () {
    test('below-minimum wins over above-balance', () {
      // Someone with 500 sats typing 1000 is told the minimum, which is the
      // actionable fact — topping up 500 sats would not help.
      final r = check(
        direction: PegDirection.pegOut,
        amount: 1000,
        balance: 500,
      );
      expect(r.issue, PegAmountIssue.belowMinimum);
    });
  });
}
