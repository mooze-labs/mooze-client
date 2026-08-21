import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/domain/entities/liquid_send_draft.dart';
import 'package:mooze_mobile/infra/lwk/liquid_fee_rate.dart';

/// Pure tests — no FFI, no wallet, no network. These guard the one piece of
/// the LWK send path that is easy to get silently wrong: the sat/vB → sat/kvB
/// conversion. v1.2 shipped `max(feeRate * 100, 26)`, which under-paid by 10x
/// against the caller's stated intent and floored below the network minimum.
/// See `LiquidFeeRate` for the full history.
void main() {
  group('LiquidFeeRate.fromSatPerVb', () {
    test('multiplies by 1000 — LWK takes sat/kvB, callers speak sat/vB', () {
      // lwk_wollet tx_builder.rs:177 — "1.0 sat/byte = 1000.0 sat/kvb"
      expect(LiquidFeeRate.fromSatPerVb(1.0), 1000.0);
      expect(LiquidFeeRate.fromSatPerVb(2.5), 2500.0);
      expect(LiquidFeeRate.fromSatPerVb(0.5), 500.0);
    });

    test('0.1 sat/vB maps exactly onto the Liquid minimum', () {
      expect(LiquidFeeRate.fromSatPerVb(0.1), LiquidFeeRate.minSatPerKvb);
      expect(LiquidFeeRate.minSatPerKvb, 100.0);
    });

    test(
      'clamps up to the minimum relay rate — never builds a rejectable tx',
      () {
        expect(LiquidFeeRate.fromSatPerVb(0.05), LiquidFeeRate.minSatPerKvb);
        expect(LiquidFeeRate.fromSatPerVb(0.0001), LiquidFeeRate.minSatPerKvb);
      },
    );

    test('falls back to the default when the fee oracle gives us nothing '
        'usable', () {
      // Upstream estimation is best-effort; refusing to build because an API
      // returned NaN is worse than paying the Liquid minimum.
      expect(LiquidFeeRate.fromSatPerVb(null), LiquidFeeRate.defaultSatPerKvb);
      expect(LiquidFeeRate.fromSatPerVb(0), LiquidFeeRate.defaultSatPerKvb);
      expect(LiquidFeeRate.fromSatPerVb(-1), LiquidFeeRate.defaultSatPerKvb);
      expect(
        LiquidFeeRate.fromSatPerVb(double.nan),
        LiquidFeeRate.defaultSatPerKvb,
      );
      expect(
        LiquidFeeRate.fromSatPerVb(double.infinity),
        LiquidFeeRate.defaultSatPerKvb,
      );
      expect(
        LiquidFeeRate.fromSatPerVb(double.negativeInfinity),
        LiquidFeeRate.defaultSatPerKvb,
      );
    });

    test('does NOT reproduce the v1.2 arithmetic', () {
      // v1.2: max(feeRate * 100, 26). A caller asking for 1.0 sat/vB got
      // 100 sat/kvB (= 0.1 sat/vB). Regression guard against a copy-paste
      // port of `liquid.dart:144`.
      expect(LiquidFeeRate.fromSatPerVb(1.0), isNot(100.0));
      expect(LiquidFeeRate.fromSatPerVb(1.0), 1000.0);
    });

    test('round-trips through toSatPerVb above the clamp', () {
      for (final rate in [0.1, 0.5, 1.0, 3.0, 42.0]) {
        expect(
          LiquidFeeRate.toSatPerVb(LiquidFeeRate.fromSatPerVb(rate)),
          closeTo(rate, 1e-9),
        );
      }
    });
  });

  group('LiquidSendDraft', () {
    LiquidSendDraft draft({
      required int amount,
      required int fee,
      bool drain = false,
    }) => LiquidSendDraft(
      pset: 'pset-base64',
      destination: 'lq1qq...',
      amountSat: BigInt.from(amount),
      feeSat: BigInt.from(fee),
      feeRateSatPerKvb: LiquidFeeRate.minSatPerKvb,
      drain: drain,
    );

    test('totalSat is what actually leaves the wallet — output plus fee', () {
      expect(draft(amount: 50000, fee: 34).totalSat, BigInt.from(50034));
    });

    test(
      'a drain draft still reports the recipient amount, not the balance',
      () {
        // The peg-out confirm sheet shows amountSat to the user; if a drain
        // reported the pre-fee balance the displayed figure would exceed what
        // SideSwap actually receives.
        final d = draft(amount: 99966, fee: 34, drain: true);
        expect(d.amountSat, BigInt.from(99966));
        expect(d.totalSat, BigInt.from(100000));
        expect(d.drain, isTrue);
      },
    );
  });
}
