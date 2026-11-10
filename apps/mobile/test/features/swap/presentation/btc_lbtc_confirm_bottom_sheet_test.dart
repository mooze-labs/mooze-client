import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_orchestrator.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/btc_lbtc_confirm_bottom_sheet.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'fake_peg_orchestrator.dart';
import 'fixed_fee_provider.dart';

/// The live quote of 30 000 sats, as the swap screen hands it over.
PegQuote liveQuote(PegDirection direction, {required int networkFeeSat}) =>
    PegQuote(
      direction: direction,
      amountSat: BigInt.from(30000),
      networkFeeSat: BigInt.from(networkFeeSat),
      serviceFeeSat: BigInt.from(30),
      minimumSat: BigInt.from(direction.isPegIn ? 10000 : 25000),
    );

void main() {
  late FakePegOrchestrator peg;

  setUp(() => peg = FakePegOrchestrator());

  Future<void> open(
    WidgetTester tester, {
    required PegQuote quote,
    BitcoinFeeEstimate? feeEstimate,
    Future<void> Function(int? feeRate, PegQuote quote)? onConfirm,
    bool lowFeeEnabled = false,
    FeeSpeed? feeSpeed,
  }) async {
    // The test font draws each glyph as a full square, so the fee rows need
    // more than the 440 pt of a phone.
    tester.view.physicalSize = const Size(1800, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The economy fee of the advanced settings.
    SharedPreferences.setMockInitialValues({
      PegLowFeeEnabledNotifier.key: lowFeeEnabled,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: Scaffold(
            body: BtcLbtcConfirmBottomSheet(
              amount: quote.amountSat,
              isPegIn: quote.direction.isPegIn,
              orchestrator: peg,
              quote: quote,
              feeEstimate: feeEstimate,
              feeSpeed: feeSpeed,
              onConfirm: onConfirm ?? (feeRate, quote) async {},
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  group('peg-in', () {
    testWidgets('opens on the live quote and asks for none', (tester) async {
      // Priced at the normal 5 sat/vB × 100 vB.
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 500),
        feeEstimate: fixedBitcoinFees(),
      );

      expect(peg.quotes, isEmpty);
      // The network fee of 500 plus the service fee of 30.
      expect(find.text('530 sats'), findsOneWidget);
      expect(find.text('29.470'), findsOneWidget);
    });

    testWidgets('opens on the economic speed the screen priced at', (
      tester,
    ) async {
      final quote = liveQuote(PegDirection.pegIn, networkFeeSat: 200);
      final confirmed = <int?>[];
      await open(
        tester,
        quote: quote,
        feeEstimate: fixedBitcoinFees(),
        feeSpeed: FeeSpeed.low,
        lowFeeEnabled: true,
        onConfirm: (feeRate, quote) async => confirmed.add(feeRate),
      );

      expect(
        tester
            .widget<FeeSpeedSelector>(find.byType(FeeSpeedSelector))
            .selectedSpeed,
        FeeSpeed.low,
      );
      // 2 sat/vB × 100 vB plus 30, with no new quote.
      expect(find.text('230 sats'), findsOneWidget);
      expect(peg.quotes, isEmpty);

      await slideToConfirm(tester);

      expect(confirmed.single, 2);
    });

    testWidgets('offers the economy fee only when the settings turn it on', (
      tester,
    ) async {
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 500),
        feeEstimate: fixedBitcoinFees(),
        lowFeeEnabled: true,
      );

      // The normal speed stays the default.
      expect(find.text('530 sats'), findsOneWidget);

      await tester.tap(find.text('Econômica'));
      await settle(tester);

      expect(peg.quotes.single.feeRateSatPerVByte, 2);
      // 2 sat/vB × 100 vB plus 30.
      expect(find.text('230 sats'), findsOneWidget);
    });

    testWidgets('offers only the normal and the fast speed', (tester) async {
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 500),
        feeEstimate: fixedBitcoinFees(),
      );

      expect(find.text('Econômica'), findsNothing);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Rápida'), findsOneWidget);
    });

    testWidgets('Confirm sends the rate the total fees were priced at', (
      tester,
    ) async {
      final quote = liveQuote(PegDirection.pegIn, networkFeeSat: 500);
      final confirmed = <({int? feeRate, PegQuote quote})>[];
      await open(
        tester,
        quote: quote,
        feeEstimate: fixedBitcoinFees(),
        onConfirm: (feeRate, quote) async =>
            confirmed.add((feeRate: feeRate, quote: quote)),
      );

      await slideToConfirm(tester);

      expect(confirmed.single.feeRate, 5);
      expect(confirmed.single.quote, same(quote));
    });

    testWidgets('another speed reprices the total fees', (tester) async {
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 200),
        feeEstimate: fixedBitcoinFees(),
      );

      await tester.tap(find.text('Rápida'));
      await settle(tester);

      expect(peg.quotes.single.feeRateSatPerVByte, 9);
      // 9 sat/vB × 100 vB plus 30.
      expect(find.text('930 sats'), findsOneWidget);
    });

    testWidgets('a new speed dims the values and keeps them visible', (
      tester,
    ) async {
      final answer = Completer<void>();
      peg.holds.add(answer);
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 500),
        feeEstimate: fixedBitcoinFees(),
      );

      await tester.tap(find.text('Rápida'));
      await settle(tester);

      // While the new quote is on its way, as the refresh of Confirm Swap.
      expect(opacityOf(tester, '530 sats'), 0.55);
      expect(opacityOf(tester, '29.470'), 0.55);
      expect(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.byType(Shimmer),
        ),
        findsNothing,
      );

      answer.complete();
      await settle(tester);

      expect(opacityOf(tester, '930 sats'), 1.0);
      expect(opacityOf(tester, '29.070'), 1.0);
    });

    testWidgets('without fee rates it shows no speeds to pick', (tester) async {
      await open(
        tester,
        quote: liveQuote(PegDirection.pegIn, networkFeeSat: 20),
      );

      expect(peg.quotes, isEmpty);
      expect(find.text('Rápida'), findsNothing);
      expect(find.text('50 sats'), findsOneWidget);
    });
  });

  testWidgets('a peg-out opens on the live quote with no fee speeds', (
    tester,
  ) async {
    await open(
      tester,
      quote: liveQuote(PegDirection.pegOut, networkFeeSat: 20),
    );

    expect(peg.quotes, isEmpty);
    expect(find.text('Rápida'), findsNothing);
    expect(find.text('50 sats'), findsOneWidget);
  });
}

/// The opacity over [text], which must be on screen.
double opacityOf(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

Future<void> slideToConfirm(WidgetTester tester) async {
  final thumb = find.descendant(
    of: find.byType(SlideToConfirmButton),
    matching: find.byWidgetPredicate(
      (w) => w is GestureDetector && w.onHorizontalDragEnd != null,
    ),
  );
  await tester.drag(thumb, const Offset(800, 0));
  await settle(tester);
}

/// Pumps frames for the quote. The sheet shimmers without end, so
/// `pumpAndSettle` would not return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
