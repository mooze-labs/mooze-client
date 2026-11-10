import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/asset_market_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_period_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Price quotes without network or cache access. No live quote, so the
/// sheet shows the last price of the history.
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

/// Size of the test screen: a phone with a home indicator.
const _screen = Size(390, 844);

/// Bottom inset of the home indicator.
const _homeIndicator = 34.0;

/// Bounds of the tappable origin on the launcher screen.
const _originRect = Rect.fromLTWH(20, 200, 350, 72);

/// Long enough for the sheet spring to settle.
const _settle = Duration(seconds: 1);

String _price(double value) =>
    NumberFormat('#,##0.00', testLocale.toString()).format(value);

/// Lets the completed history reach the widget: one frame for the provider
/// state, one frame for the rebuild.
Future<void> _receiveData(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Sets the test screen to [_screen] with the home indicator inset.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = _screen * 3;
  tester.view.padding = const FakeViewPadding(bottom: _homeIndicator * 3);
  addTearDown(tester.view.reset);
}

/// Bounds of the sheet glass. It is the first glass of the route.
Rect _glassRect(WidgetTester tester) =>
    tester.getRect(find.byType(LiquidGlass).first);

/// Taps the launcher and pumps to the first frame of the sheet: one frame
/// for the press, one for the route.
Future<void> _tapOpen(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump();
}

/// Checks that the launcher origin is on screen and unchanged: the sheet
/// grows out of it but never hides or copies it.
void _expectOriginVisible(WidgetTester tester) {
  expect(find.text('open'), findsOneWidget);
  expect(tester.getRect(find.byType(GlassSheetOrigin)), _originRect);
  expect(
    find.ancestor(of: find.text('open'), matching: find.byType(Opacity)),
    findsNothing,
  );
  expect(find.byType(RawImage), findsNothing);
}

/// Stores [prices] as the cached 1D history of BTC, [age] old.
void _cacheDay(
  List<double> prices, {
  Duration age = const Duration(minutes: 10),
}) {
  final key = MarketHistoryRepository.keyOf(
    Asset.btc,
    Currency.brl,
    MarketPeriod.day,
  );
  SharedPreferences.setMockInitialValues({
    'cached_price_history_$key': CachedPriceHistory(
      prices: prices,
      fetchedAt: DateTime.now().subtract(age),
    ).toJsonString(),
  });
}

/// Width factor of the reveal clip around the chart.
double _revealOf(WidgetTester tester) => tester
    .widget<Align>(
      find.descendant(
        of: find.byType(MarketChart),
        matching: find.byWidgetPredicate(
          (widget) => widget is Align && widget.widthFactor != null,
        ),
      ),
    )
    .widthFactor!;

/// How much shows of the chart state that [finder] finds: the product of
/// the fades inside the switcher above it, 0 when it is gone. The dimming
/// of a loading chart is a fade too.
double _shownOf(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) return 0;
  final fades = find.ancestor(
    of: finder,
    matching: find.descendant(
      of: find.byType(MarketChartSwitcher),
      matching: find.byType(FadeTransition),
    ),
  );
  return tester
      .widgetList<FadeTransition>(fades)
      .fold(1.0, (shown, fade) => shown * fade.opacity.value);
}

/// The loading wrapper of the chart.
MarketChartUpdating _updating(WidgetTester tester) =>
    tester.widget<MarketChartUpdating>(find.byType(MarketChartUpdating));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Requests of the price history per period length, oldest first. Each
  /// request gets its own completer, so a test can answer requests out of
  /// order.
  late Map<int, List<Completer<_History>>> requests;

  /// Bounds of the origin on the launcher. A test moves it, as a scroll
  /// would move an asset row.
  final origin = ValueNotifier(_originRect);
  tearDown(() => origin.value = _originRect);

  /// Answers the latest request for [period].
  void answer(MarketPeriod period, _History history) =>
      requests[period.days]!.last.complete(history);

  /// A screen with one origin that opens the market sheet of BTC.
  Widget launcher() => ProviderScope(
    overrides: [
      priceHistoryFetcherProvider.overrideWithValue((params) {
        final request = Completer<_History>();
        requests.putIfAbsent(params.periodInDays, () => []).add(request);
        return request.future;
      }),
      priceQuotesProvider.overrideWith((ref) => _FakeQuotes()),
      currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
      isUsingCacheProvider.overrideWithValue(false),
    ],
    child: wrapForTest(
      Scaffold(
        body: Stack(
          children: [
            ValueListenableBuilder<Rect>(
              valueListenable: origin,
              builder: (context, rect, child) =>
                  Positioned.fromRect(rect: rect, child: child!),
              child: GlassSheetOrigin(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () =>
                        showAssetMarketSheet(context, asset: Asset.btc),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    requests = {};
    _usePhoneScreen(tester);
    await tester.pumpWidget(launcher());
    await _tapOpen(tester);
    // The skeletons shimmer while the history loads, so the test pumps
    // through the sheet entrance instead of waiting for the screen to
    // settle.
    await tester.pump(_settle);
  }

  /// Opens the sheet and shows the 1D chart of [klines].
  Future<void> openWithChart(WidgetTester tester, List<double> klines) async {
    await open(tester);
    answer(MarketPeriod.day, right(klines));
    await _receiveData(tester);
    await tester.pumpAndSettle();
  }

  /// Checks that the glass floats at its open place.
  void expectOpen(WidgetTester tester) {
    final rect = _glassRect(tester);
    expect(rect.left, moreOrLessEquals(GlassSheet.sideMargin));
    expect(rect.right, moreOrLessEquals(_screen.width - GlassSheet.sideMargin));
    expect(
      _screen.height - rect.bottom,
      moreOrLessEquals(_homeIndicator - 8, epsilon: 0.5),
    );
  }

  group('Expansion', () {
    testWidgets('the sheet grows out of the origin to its floating place', (
      tester,
    ) async {
      requests = {};
      _usePhoneScreen(tester);
      await tester.pumpWidget(launcher());
      await _tapOpen(tester);

      // First frame: the glass starts on the bounds of the origin, and the
      // origin stays as it is.
      final start = _glassRect(tester);
      expect(start.topLeft, offsetMoreOrLessEquals(_originRect.topLeft));
      expect(start.width, moreOrLessEquals(_originRect.width));
      expect(start.height, moreOrLessEquals(_originRect.height));
      _expectOriginVisible(tester);

      await tester.pump(Motion.durationEmphasis ~/ 2);
      final midway = _glassRect(tester);
      expect(midway.height, greaterThan(_originRect.height));
      expect(midway.left, lessThan(_originRect.left));
      _expectOriginVisible(tester);

      await tester.pump(_settle);
      expectOpen(tester);
      expect(find.text(Asset.btc.name), findsOneWidget);
      expect(find.text(Asset.btc.ticker), findsOneWidget);
    });

    /// Opacity of the nearest fade above [target].
    double fadeAround(WidgetTester tester, Finder target) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: target, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    testWidgets('the glass shows on the origin before the content', (
      tester,
    ) async {
      requests = {};
      _usePhoneScreen(tester);
      await tester.pumpWidget(launcher());
      await _tapOpen(tester);

      // Pump frame by frame until the glass is fully there.
      var frames = 0;
      while (fadeAround(tester, find.byType(LiquidGlass).first) < 1) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      expect(frames, greaterThan(0));
      // The content waits for the glass, and the glass is still on the
      // origin: it grows out of it.
      expect(fadeAround(tester, find.byType(AssetMarketSheet)), lessThan(0.1));
      expect(_glassRect(tester).overlaps(_originRect), isTrue);
      _expectOriginVisible(tester);
      await tester.pump(_settle);
    });

    /// Closes the sheet and returns the bounds of the glass in its last
    /// frame.
    Future<Rect> closeAndTrack(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      var last = _glassRect(tester);
      while (find.byType(AssetMarketSheet).evaluate().isNotEmpty) {
        last = _glassRect(tester);
        await tester.pump(const Duration(milliseconds: 16));
      }
      return last;
    }

    testWidgets('closing ends on the exact bounds of the origin', (
      tester,
    ) async {
      await open(tester);

      final last = await closeAndTrack(tester);
      expect(
        last.topLeft,
        offsetMoreOrLessEquals(_originRect.topLeft, epsilon: 2),
      );
      expect(last.size.width, moreOrLessEquals(_originRect.width, epsilon: 2));
      expect(
        last.size.height,
        moreOrLessEquals(_originRect.height, epsilon: 2),
      );
      _expectOriginVisible(tester);
    });

    testWidgets('closing follows an origin that moved while the sheet was '
        'open', (tester) async {
      await open(tester);
      const moved = Rect.fromLTWH(20, 120, 350, 72);
      origin.value = moved;
      await tester.pump();

      final last = await closeAndTrack(tester);
      expect(last.topLeft, offsetMoreOrLessEquals(moved.topLeft, epsilon: 2));
      expect(last.size.height, moreOrLessEquals(moved.height, epsilon: 2));
    });

    testWidgets('the close button shrinks the sheet back into the origin', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump(Motion.durationEmphasis ~/ 2);
      final midway = _glassRect(tester);
      expect(midway.top, lessThan(_screen.height / 2));
      _expectOriginVisible(tester);

      await tester.pump(_settle);
      expect(find.byType(AssetMarketSheet), findsNothing);
      // The origin is where it was, with nothing in front of it.
      _expectOriginVisible(tester);
      expect(find.byType(LiquidGlass), findsNothing);
    });

    testWidgets('the dimming covers the whole screen evenly, the origin '
        'included', (tester) async {
      await open(tester);

      // One even layer of the barrier color over the full screen, with no
      // cut-out, rim, or glow around the origin.
      final dim = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == Colors.black54,
      );
      expect(dim, findsOneWidget);
      expect(tester.getRect(dim), Offset.zero & _screen);
      _expectOriginVisible(tester);
    });

    testWidgets('a tap outside closes the sheet', (tester) async {
      await open(tester);

      await tester.tapAt(const Offset(195, 40));
      await tester.pump();
      await tester.pump(_settle);

      expect(find.byType(AssetMarketSheet), findsNothing);
      _expectOriginVisible(tester);
    });

    testWidgets('a long downward drag closes the sheet, a short one settles '
        'back', (tester) async {
      await openWithChart(tester, [1, 2, 3]);
      final rest = _glassRect(tester);

      await tester.drag(find.text(Asset.btc.ticker), const Offset(0, 40));
      await tester.pump();
      expect(_glassRect(tester).top, greaterThan(rest.top));
      await tester.pumpAndSettle();
      expect(_glassRect(tester).top, moreOrLessEquals(rest.top, epsilon: 0.01));

      await tester.drag(find.text(Asset.btc.ticker), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.byType(AssetMarketSheet), findsNothing);
      _expectOriginVisible(tester);
    });

    testWidgets('a horizontal drag on the chart scrubs and keeps the sheet', (
      tester,
    ) async {
      final klines = [for (var i = 0; i < 24; i++) 100.0 + i];
      await openWithChart(tester, klines);
      final rest = _glassRect(tester);

      final chart = tester.getRect(find.byType(LineChart));
      final gesture = await tester.startGesture(
        chart.centerLeft + const Offset(4, 0),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();

      expect(_glassRect(tester), rest);
      expect(find.text(_price(klines.last)), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(AssetMarketSheet), findsOneWidget);
    });

    testWidgets('reduced motion opens and closes at once', (tester) async {
      reduceMotion(tester);
      requests = {};
      _usePhoneScreen(tester);
      await tester.pumpWidget(launcher());
      await _tapOpen(tester);
      await tester.pump();
      expectOpen(tester);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AssetMarketSheet), findsNothing);
      _expectOriginVisible(tester);
    });
  });

  group('Content', () {
    testWidgets('shows the price, the change, and the period stats', (
      tester,
    ) async {
      await openWithChart(tester, [100, 300, 200, 150]);

      // Price hero: the last price and +50% from the open.
      expect(find.text(_price(150)), findsOneWidget);
      expect(find.text('+${_price(50)}%'), findsOneWidget);
      // Stats: open and low (both 100), and high.
      expect(find.text('R\$ ${_price(100)}'), findsNWidgets(2));
      expect(find.text('R\$ ${_price(300)}'), findsOneWidget);
      expect(find.text('R\$ ${_price(150)}'), findsNothing);
    });

    testWidgets('the first show reveals the chart from left to right', (
      tester,
    ) async {
      await open(tester);
      answer(MarketPeriod.day, right([1, 3, 2, 4]));
      await _receiveData(tester);

      expect(_revealOf(tester), lessThan(1));
      await tester.pump(Motion.durationChartDraw ~/ 2);
      expect(_revealOf(tester), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_revealOf(tester), 1);
    });

    testWidgets('the first chart comes after the skeleton has left, never '
        'through it', (tester) async {
      await open(tester);
      expect(find.byType(MarketChartSkeleton), findsOneWidget);
      answer(MarketPeriod.day, right([1, 3, 2, 4]));
      await _receiveData(tester);

      for (var frame = 0; frame < 30; frame++) {
        final skeleton = _shownOf(tester, find.byType(MarketChartSkeleton));
        final chart = _shownOf(tester, find.byType(MarketChart));
        expect(
          skeleton == 0 || chart == 0,
          isTrue,
          reason: 'frame $frame: $skeleton, $chart',
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(MarketChartSkeleton), findsNothing);
      expect(_shownOf(tester, find.byType(MarketChart)), 1);
    });

    testWidgets('the period lens slides under the selected period', (
      tester,
    ) async {
      await openWithChart(tester, [1, 2]);

      Offset lensCenter() => tester.getCenter(
        find.descendant(
          of: find.byType(MarketPeriodSelector),
          matching: find.byType(GlassLens),
        ),
      );
      double labelCenter(MarketPeriod period) =>
          tester.getCenter(find.text(period.label)).dx;

      expect(lensCenter().dx, closeTo(labelCenter(MarketPeriod.day), 1));

      await tester.tap(find.text(MarketPeriod.month.label));
      await tester.pump();
      await tester.pump(Motion.durationFast ~/ 2);
      expect(
        lensCenter().dx,
        inExclusiveRange(
          labelCenter(MarketPeriod.day),
          labelCenter(MarketPeriod.month),
        ),
      );

      await tester.pump(Motion.durationFast);
      expect(lensCenter().dx, closeTo(labelCenter(MarketPeriod.month), 1));
    });

    testWidgets('a scrub shows the point under the finger, with throttled '
        'haptics, and returns to the live price at the end', (tester) async {
      var clicks = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') clicks++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final klines = [for (var i = 0; i < 24; i++) 100.0 + i];
      await openWithChart(tester, klines);
      expect(find.text(_price(klines.last)), findsOneWidget);

      final chart = tester.getRect(find.byType(LineChart));
      final gesture = await tester.startGesture(
        chart.centerLeft + const Offset(4, 0),
      );
      await tester.pump();
      // The start of the period: price 100, no change.
      expect(find.text(_price(klines.first)), findsOneWidget);

      // Drag across all points in 200 ms: 23 new points, at most one click
      // per 80 ms.
      for (var i = 1; i <= 20; i++) {
        await gesture.moveBy(Offset((chart.width - 8) / 20, 0));
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(clicks, inInclusiveRange(1, 4));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(_price(klines.last)), findsOneWidget);
    });

    testWidgets('reduced motion shows the chart at once and swaps data at '
        'once', (tester) async {
      reduceMotion(tester);
      await open(tester);
      answer(MarketPeriod.day, right([1, 3, 2, 4]));
      await _receiveData(tester);

      expect(_revealOf(tester), 1);
      expect(
        tester.widget<LineChart>(find.byType(LineChart)).duration,
        Duration.zero,
      );
    });
  });

  group('Period loading', () {
    testWidgets('a period change dims the last chart and shows the loading '
        'pill until the data arrives', (tester) async {
      await openWithChart(tester, [1, 3, 2, 4]);
      expect(_updating(tester).updating, isFalse);

      await tester.tap(find.text(MarketPeriod.week.label));
      await tester.pump();

      // At once: the old chart stays, dims, and shows the pill.
      expect(_updating(tester).updating, isTrue);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(MarketChartSkeleton), findsNothing);
      expect(find.text('Carregando...'), findsOneWidget);
      await tester.pump(Motion.durationFast);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: find.byType(MarketChartUpdating),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        MarketChartUpdating.dimmedOpacity,
      );
      // The hero still describes the chart on screen.
      expect(find.text('24 horas'), findsOneWidget);

      answer(MarketPeriod.week, right([4, 2, 3, 1]));
      await _receiveData(tester);

      expect(_updating(tester).updating, isFalse);
      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.duration, Motion.durationEmphasis);
      expect(lineChart.curve, Motion.curveMove);
      // The reveal does not play again.
      expect(_revealOf(tester), 1);

      await tester.pumpAndSettle();
      expect(find.text('Carregando...'), findsNothing);
      expect(find.text(_price(1)), findsWidgets);
    });

    testWidgets('only the last selected period ends the loading state', (
      tester,
    ) async {
      await openWithChart(tester, [10, 11]);

      await tester.tap(find.text(MarketPeriod.week.label));
      await tester.pump();
      await tester.tap(find.text(MarketPeriod.month.label));
      await tester.pump();

      // The 7D answer comes late, after the user moved on to 1M.
      answer(MarketPeriod.week, right([70, 77]));
      await _receiveData(tester);
      expect(_updating(tester).updating, isTrue);
      expect(find.text(_price(77)), findsNothing);
      expect(find.text(_price(11)), findsOneWidget);

      answer(MarketPeriod.month, right([30, 33]));
      await _receiveData(tester);
      await tester.pumpAndSettle();
      expect(_updating(tester), isNotNull);
      expect(_updating(tester).updating, isFalse);
      expect(find.text(_price(33)), findsOneWidget);
      expect(find.text(_price(77)), findsNothing);
    });

    testWidgets('a failed period ends the loading state and can retry', (
      tester,
    ) async {
      await openWithChart(tester, [1, 2]);

      await tester.tap(find.text(MarketPeriod.week.label));
      await tester.pump();
      answer(MarketPeriod.week, left('timeout'));
      await _receiveData(tester);
      await tester.pumpAndSettle();

      expect(find.byType(MarketChartUpdating), findsNothing);
      expect(find.byType(MarketChartUnavailable), findsOneWidget);
      expect(find.text('Carregando...'), findsNothing);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(requests[MarketPeriod.week.days], hasLength(2));
      expect(find.byType(MarketChartSkeleton), findsOneWidget);

      answer(MarketPeriod.week, right([5, 6]));
      await _receiveData(tester);
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text(_price(6)), findsOneWidget);
    });

    testWidgets('a failed first load shows the unavailable state', (
      tester,
    ) async {
      await open(tester);
      answer(MarketPeriod.day, left('offline'));
      await _receiveData(tester);
      await tester.pumpAndSettle();

      expect(find.byType(MarketChartUnavailable), findsOneWidget);
      expect(find.text('N/A'), findsWidgets);
    });

    testWidgets('reduced motion shows the loading state without a spinner', (
      tester,
    ) async {
      reduceMotion(tester);
      await openWithChart(tester, [1, 2]);

      await tester.tap(find.text(MarketPeriod.week.label));
      await tester.pump();

      expect(find.text('Carregando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Cache', () {
    testWidgets('a cached history shows at once and refreshes in the '
        'background', (tester) async {
      _cacheDay([10, 20]);
      await open(tester);

      // No skeleton and no loading pill: the cached chart is on screen.
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(MarketChartSkeleton), findsNothing);
      expect(find.text('Carregando...'), findsNothing);
      expect(find.text(_price(20)), findsOneWidget);
      // A silent refresh runs.
      expect(requests[MarketPeriod.day.days], hasLength(1));

      answer(MarketPeriod.day, right([10, 30]));
      await _receiveData(tester);
      await tester.pumpAndSettle();
      expect(find.text(_price(30)), findsOneWidget);
      expect(find.byType(MarketChartSkeleton), findsNothing);
    });

    testWidgets('a failed refresh keeps the cached chart', (tester) async {
      _cacheDay([10, 20]);
      await open(tester);

      answer(MarketPeriod.day, left('offline'));
      await _receiveData(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(MarketChartUnavailable), findsNothing);
      expect(find.text(_price(20)), findsOneWidget);
    });

    testWidgets('a refresh waits until the user lets go of the chart', (
      tester,
    ) async {
      final cached = [for (var i = 0; i < 24; i++) 100.0 + i];
      _cacheDay(cached);
      await open(tester);
      await tester.pumpAndSettle();

      final chart = tester.getRect(find.byType(MarketChart));
      final gesture = await tester.startGesture(
        chart.centerLeft + const Offset(4, 0),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      final held = tester.widget<MarketChart>(find.byType(MarketChart)).klines;

      answer(MarketPeriod.day, right([for (var i = 0; i < 24; i++) 200.0 + i]));
      await _receiveData(tester);
      expect(
        tester.widget<MarketChart>(find.byType(MarketChart)).klines,
        same(held),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(_price(223)), findsOneWidget);
    });
  });

  group('Range', () {
    /// 24 hourly points from 100 to 123.
    final rising = [for (var i = 0; i < 24; i++) 100.0 + i];

    /// Returns the screen position of the point at [index].
    Offset pointAt(WidgetTester tester, int index, int length) {
      final chart = tester.getRect(find.byType(MarketChart));
      return Offset(
        chart.left + index / (length - 1) * chart.width,
        chart.top + chart.height / 3,
      );
    }

    /// Long-presses the point at [from], drags to [to], and lifts.
    Future<void> selectRange(
      WidgetTester tester,
      int from,
      int to,
      int length,
    ) async {
      final gesture = await tester.startGesture(pointAt(tester, from, length));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(pointAt(tester, to, length));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a long press and a drag select a range with its change, '
        'length, and both ends', (tester) async {
      await openWithChart(tester, rising);
      await selectRange(tester, 2, 12, rising.length);

      // Hero: the end price, the change from the start, and the length.
      expect(find.text(_price(112)), findsOneWidget);
      expect(find.text('+${_price(10 / 102 * 100)}%'), findsOneWidget);
      expect(find.text('+R\$ ${_price(10)}'), findsOneWidget);
      expect(find.text('10 horas'), findsOneWidget);
      // Ends: real points of the history.
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Fim'), findsOneWidget);
      expect(find.text('R\$ ${_price(102)}'), findsOneWidget);
      expect(find.text('R\$ ${_price(112)}'), findsOneWidget);
      expect(find.byTooltip('Limpar intervalo'), findsOneWidget);
    });

    testWidgets('a drag after the selection moves the nearest marker', (
      tester,
    ) async {
      await openWithChart(tester, rising);
      await selectRange(tester, 2, 12, rising.length);

      await tester.dragFrom(
        pointAt(tester, 11, rising.length),
        pointAt(tester, 20, rising.length) - pointAt(tester, 11, rising.length),
      );
      await tester.pumpAndSettle();

      expect(find.text('18 horas'), findsOneWidget);
      expect(find.text('R\$ ${_price(120)}'), findsOneWidget);
      expect(find.text('R\$ ${_price(102)}'), findsOneWidget);
    });

    testWidgets('a falling range shows a negative change', (tester) async {
      final falling = [for (var i = 0; i < 24; i++) 200.0 - i];
      await openWithChart(tester, falling);
      await selectRange(tester, 0, 4, falling.length);

      expect(find.text('−${_price(4 / 200 * 100)}%'), findsOneWidget);
      expect(find.text('−R\$ ${_price(4)}'), findsOneWidget);
    });

    testWidgets('a range on 7D measures days and hours', (tester) async {
      await openWithChart(tester, [1, 2]);
      await tester.tap(find.text(MarketPeriod.week.label));
      await tester.pump();
      final week = [for (var i = 0; i < 42; i++) 50.0 + i];
      answer(MarketPeriod.week, right(week));
      await _receiveData(tester);
      await tester.pumpAndSettle();

      // 7 points of 4 hours.
      await selectRange(tester, 3, 10, week.length);
      expect(find.text('1 d 4 h'), findsOneWidget);
    });

    testWidgets('a tap on the chart or the clear button ends the range', (
      tester,
    ) async {
      await openWithChart(tester, rising);
      await selectRange(tester, 2, 12, rising.length);

      await tester.tapAt(pointAt(tester, 6, rising.length));
      await tester.pumpAndSettle();
      expect(find.text('Início'), findsNothing);
      expect(find.text(_price(123)), findsOneWidget);

      await selectRange(tester, 2, 12, rising.length);
      await tester.tap(find.byTooltip('Limpar intervalo'));
      await tester.pumpAndSettle();
      expect(find.text('Início'), findsNothing);
      // Scrubbing works again.
      final gesture = await tester.startGesture(
        pointAt(tester, 0, rising.length),
      );
      await tester.pump();
      expect(find.text(_price(100)), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a vertical drag on the chart keeps the sheet while a range '
        'is shown', (tester) async {
      await openWithChart(tester, rising);
      await selectRange(tester, 2, 12, rising.length);

      await tester.dragFrom(
        pointAt(tester, 12, rising.length),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssetMarketSheet), findsOneWidget);
      expect(find.text('Início'), findsOneWidget);
    });
  });
}
