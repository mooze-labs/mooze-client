import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/swap/di/providers/peg_providers.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/peg_quote_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_peg_orchestrator.dart';
import 'fixed_fee_provider.dart';

void main() {
  late FakePegOrchestrator peg;
  late FixedFeeProvider fees;

  setUp(() {
    peg = FakePegOrchestrator();
    fees = FixedFeeProvider();
  });

  /// [lowFeeEnabled] is the economy fee of the advanced settings.
  Future<ProviderContainer> container({bool lowFeeEnabled = false}) async {
    SharedPreferences.setMockInitialValues({
      PegLowFeeEnabledNotifier.key: lowFeeEnabled,
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        pegOrchestratorProvider.overrideWithValue(peg),
        bitcoinFeeServiceProvider.overrideWithValue(fees.service),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(c.dispose);
    c.listen(pegQuoteControllerProvider, (_, _) {});
    return c;
  }

  PegQuoteRequest out(int sats, {bool drain = false}) => PegQuoteRequest(
    direction: PegDirection.pegOut,
    amountSat: BigInt.from(sats),
    drain: drain,
  );

  PegQuoteRequest into(int sats, {bool drain = false}) => PegQuoteRequest(
    direction: PegDirection.pegIn,
    amountSat: BigInt.from(sats),
    drain: drain,
  );

  test('a valid amount gets its quote', () async {
    final c = await container();

    await c.read(pegQuoteControllerProvider.notifier).request(out(30000));

    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(out(30000)), isTrue);
    expect(state.quote!.estimatedReceiveSat, BigInt.from(29950));
  });

  test('an amount below the minimum fails with the minimum', () async {
    final c = await container();

    await c.read(pegQuoteControllerProvider.notifier).request(out(12000));

    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(out(12000)), isFalse);
    expect(
      state.errorFor(out(12000)),
      isA<PegBelowMinimum>().having((e) => e.minimumSat, 'minimum', 25000),
    );
  });

  test('Max on 1 015 sats of L-BTC is below the minimum', () async {
    final c = await container();
    final max = out(1015, drain: true);

    await c.read(pegQuoteControllerProvider.notifier).request(max);

    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(max), isFalse);
    expect(state.errorFor(max), isA<PegBelowMinimum>());
  });

  test('a late answer of an older amount is dropped', () async {
    final c = await container();
    final slow = Completer<void>();
    peg.holds.add(slow);
    final controller = c.read(pegQuoteControllerProvider.notifier);

    final first = controller.request(out(30000));
    await controller.request(out(40000));
    slow.complete();
    await first;

    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(out(40000)), isTrue);
    expect(state.isReadyFor(out(30000)), isFalse);
  });

  test('a quote answers only the amount it was asked for', () async {
    final c = await container();

    await c.read(pegQuoteControllerProvider.notifier).request(out(30000));

    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(out(30001)), isFalse);
    expect(state.isReadyFor(out(30000, drain: true)), isFalse);
  });

  test('clear forgets the quote', () async {
    final c = await container();
    final controller = c.read(pegQuoteControllerProvider.notifier);
    await controller.request(out(30000));

    controller.clear();

    expect(c.read(pegQuoteControllerProvider).isReadyFor(out(30000)), isFalse);
    expect(
      c.read(pegQuoteControllerProvider).isLoadingFor(out(30000)),
      isFalse,
    );
  });

  test('a peg-in is priced at the normal rate', () async {
    final c = await container();

    await c.read(pegQuoteControllerProvider.notifier).request(into(30000));

    expect(peg.quotes.single.feeRateSatPerVByte, 5);
    final state = c.read(pegQuoteControllerProvider);
    expect(state.isReadyFor(into(30000)), isTrue);
    // The sheet opens on these rates, with the normal speed selected.
    expect(state.feeEstimate!.mediumFeeSatPerVByte, 5);
    expect(state.feeSpeed, FeeSpeed.medium);
    // 5 sat/vB × 100 vB plus the service fee of 30.
    expect(state.quote!.totalFeeSat, BigInt.from(530));
  });

  test('with the economy fee on, a peg-in is priced at its rate', () async {
    final c = await container(lowFeeEnabled: true);

    await c.read(pegQuoteControllerProvider.notifier).request(into(30000));

    expect(peg.quotes.single.feeRateSatPerVByte, 2);
    final state = c.read(pegQuoteControllerProvider);
    expect(state.feeSpeed, FeeSpeed.low);
    // 2 sat/vB × 100 vB plus 30.
    expect(state.quote!.totalFeeSat, BigInt.from(230));
  });

  test(
    'turning the economy fee on prices the peg-in on screen again',
    () async {
      final c = await container();
      await c.read(pegQuoteControllerProvider.notifier).request(into(30000));

      await c.read(pegLowFeeEnabledProvider.notifier).setEnabled(true);
      await settle();

      expect(peg.quotes.map((q) => q.feeRateSatPerVByte), [5, 2]);
      final state = c.read(pegQuoteControllerProvider);
      expect(state.isReadyFor(into(30000)), isTrue);
      expect(state.feeSpeed, FeeSpeed.low);
    },
  );

  test('the setting leaves a peg-out alone', () async {
    final c = await container();
    await c.read(pegQuoteControllerProvider.notifier).request(out(30000));

    await c.read(pegLowFeeEnabledProvider.notifier).setEnabled(true);
    await settle();

    expect(peg.quotes, hasLength(1));
    expect(c.read(pegQuoteControllerProvider).feeSpeed, isNull);
  });

  test('a peg-out asks for no Bitcoin fee rate', () async {
    final c = await container();

    await c.read(pegQuoteControllerProvider.notifier).request(out(30000));

    expect(peg.quotes.single.feeRateSatPerVByte, isNull);
    expect(c.read(pegQuoteControllerProvider).feeEstimate, isNull);
    expect(fees.fetches, 0);
  });

  test('the fee rates are fetched once for the screen', () async {
    final c = await container();
    final controller = c.read(pegQuoteControllerProvider.notifier);

    await controller.request(into(30000));
    await controller.request(into(40000));
    await controller.request(into(0, drain: true));

    expect(fees.fetches, 1);
    expect(peg.quotes.map((q) => q.feeRateSatPerVByte), everyElement(5));
  });
}

/// Lets the quote that the setting started answer.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
