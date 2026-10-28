import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_chart_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Price quotes without network or cache access.
class _FakeQuotes extends StateNotifier<PriceQuotes>
    implements PriceQuotesNotifier {
  _FakeQuotes() : super(PriceQuotes.initial(Currency.brl));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

typedef _History = Either<String, List<double>>;

/// Lets the completed history reach the widget: one frame for the provider
/// state, one frame for the rebuild.
Future<void> _receiveData(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  late Map<int, Completer<_History>> histories;

  /// Creates the price histories. Call it inside the test body: a future
  /// from `setUp` completes outside the fake async zone of the test.
  void newHistories() {
    histories = {
      1: Completer<_History>(),
      7: Completer<_History>(),
      30: Completer<_History>(),
    };
  }

  Widget chart(TimePeriod period) => ProviderScope(
    overrides: [
      assetPriceHistoryWithPeriodProvider.overrideWith(
        (ref, params) => histories[params.periodInDays]!.future,
      ),
      priceQuotesProvider.overrideWith((ref) => _FakeQuotes()),
      currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
    ],
    child: wrapForTest(
      Scaffold(
        body: AssetChartWidget(asset: Asset.btc, selectedPeriod: period),
      ),
    ),
  );

  /// Width factor of the reveal clip around the chart.
  double revealOf(WidgetTester tester) => tester
      .widget<Align>(
        find.descendant(
          of: find.byType(AssetChartWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is Align && widget.widthFactor != null,
          ),
        ),
      )
      .widthFactor!;

  testWidgets('the first show reveals the chart from left to right', (
    tester,
  ) async {
    newHistories();
    await tester.pumpWidget(chart(TimePeriod.day));
    histories[1]!.complete(right([1, 3, 2, 4]));
    await _receiveData(tester);

    expect(revealOf(tester), 0);
    await tester.pump(Motion.durationChartDraw ~/ 2);
    expect(revealOf(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(revealOf(tester), 1);
  });

  testWidgets('a period change keeps the chart and morphs the line', (
    tester,
  ) async {
    newHistories();
    await tester.pumpWidget(chart(TimePeriod.day));
    histories[1]!.complete(right([1, 3, 2, 4]));
    await _receiveData(tester);
    await tester.pumpAndSettle();

    await tester.pumpWidget(chart(TimePeriod.week));
    await tester.pump();

    // While the new period loads, the old chart stays. No skeleton.
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(Shimmer), findsNothing);

    histories[7]!.complete(right([4, 2, 3, 1]));
    await _receiveData(tester);

    final lineChart = tester.widget<LineChart>(find.byType(LineChart));
    expect(lineChart.duration, Motion.durationEmphasis);
    expect(lineChart.curve, Motion.curveMove);
    // The reveal does not play again.
    expect(revealOf(tester), 1);

    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion shows the chart at once and swaps data at once', (
    tester,
  ) async {
    newHistories();
    reduceMotion(tester);
    await tester.pumpWidget(chart(TimePeriod.day));
    histories[1]!.complete(right([1, 3, 2, 4]));
    await _receiveData(tester);

    expect(revealOf(tester), 1);
    expect(
      tester.widget<LineChart>(find.byType(LineChart)).duration,
      Duration.zero,
    );
  });
}
