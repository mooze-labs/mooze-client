import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/portfolio_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/portfolio_history_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/balance_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';

import '../../../../../shared/test_app.dart';

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Balance visibility without storage access.
class _FakeVisibility extends StateNotifier<bool>
    implements VisibilityNotifier {
  _FakeVisibility(super.hidden);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Hourly values of the current holdings over the last day.
final _day = [for (var i = 0; i < 24; i++) 1000.0 + i * 10];

/// Daily values over the last week.
final _week = [for (var i = 0; i < 7; i++) 2000.0 - i * 10];

/// The hero with a tappable change chip of +0,08% that opens the sheet.
Widget _launcher({
  AsyncValue<PortfolioHistory?> Function(MarketPeriod period)? history,
  bool hidden = false,
}) => ProviderScope(
  overrides: [
    portfolioHistoryProvider.overrideWith(
      (ref, period) =>
          history?.call(period) ??
          AsyncValue.data(
            PortfolioHistory(
              values: period == MarketPeriod.day ? _day : _week,
              end: DateTime(2026, 11, 1, 12),
            ),
          ),
    ),
    currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
    isVisibleProvider.overrideWith((ref) => _FakeVisibility(hidden)),
  ],
  child: wrapForTest(
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: BalanceHeroView(
          amount: const AsyncData(null),
          mode: 'fiat',
          isHidden: hidden,
          variation: const AsyncData(0.08),
          onToggleVisibility: () {},
          onCycleMode: () {},
          onVariationTap: showPortfolioHistorySheet,
        ),
      ),
    ),
  ),
);

/// Taps the change chip and lets the sheet settle.
Future<void> _open(WidgetTester tester, Widget launcher) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(launcher);
  await tester.tap(find.byType(ChangeChip));
  await tester.pumpAndSettle();
}

/// The text of the sheet below its header.
Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(PortfolioHistorySheet), matching: finder);

void main() {
  group('Change chip', () {
    Widget hero({void Function(BuildContext)? onTap}) => wrapForTest(
      Scaffold(
        body: BalanceHeroView(
          amount: const AsyncData(null),
          mode: 'fiat',
          isHidden: false,
          variation: const AsyncData(0.08),
          onToggleVisibility: () {},
          onCycleMode: () {},
          onVariationTap: onTap,
        ),
      ),
    );

    testWidgets('a tap runs the callback with a context below the origin', (
      tester,
    ) async {
      BuildContext? origin;
      await tester.pumpWidget(hero(onTap: (context) => origin = context));

      await tester.tap(find.byType(ChangeChip));
      expect(origin, isNotNull);
      expect(GlassSheetOrigin.maybeOf(origin!), isNotNull);
    });

    testWidgets('without a callback, the chip stays as it was', (tester) async {
      await tester.pumpWidget(hero());

      expect(find.byType(ChangeChip), findsOneWidget);
      expect(find.byType(GlassSheetOrigin), findsNothing);
    });
  });

  group('Sheet', () {
    testWidgets('grows out of the chip and shows the portfolio history', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_launcher());
      final chip = tester.getRect(find.byType(GlassSheetOrigin));

      await tester.tap(find.byType(ChangeChip));
      await tester.pump();
      // First frame: the glass starts on the chip.
      final start = tester.getRect(find.byType(LiquidGlass).first);
      expect(start.topLeft, offsetMoreOrLessEquals(chip.topLeft));
      expect(start.height, moreOrLessEquals(chip.height));

      await tester.pumpAndSettle();
      expect(_inSheet(find.text('Histórico da carteira')), findsOneWidget);
      // 1000 → 1230: the last value, +23% and +R$ 230 over 24 hours.
      expect(_inSheet(find.text('1.230,00')), findsOneWidget);
      expect(_inSheet(find.text('+23,00%')), findsOneWidget);
      expect(_inSheet(find.text('+R\$ 230,00')), findsOneWidget);
      expect(_inSheet(find.text('24 horas')), findsWidgets);
      // Open, high, and low.
      expect(_inSheet(find.text('R\$ 1.000,00')), findsNWidgets(2));
      expect(_inSheet(find.text('R\$ 1.230,00')), findsOneWidget);
      // The note says what the values are.
      expect(
        _inSheet(find.textContaining('Valor dos seus ativos atuais')),
        findsOneWidget,
      );
      expect(find.byType(MarketChart), findsOneWidget);
    });

    testWidgets('before any chart exists, the plot shows a loading pill and '
        'never a skeleton, and the chart then fades in alone', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      var loading = true;
      await tester.pumpWidget(
        _launcher(
          history: (period) => loading
              ? const AsyncValue.loading()
              : AsyncValue.data(
                  PortfolioHistory(values: _day, end: DateTime(2026, 11, 1)),
                ),
        ),
      );
      await tester.tap(find.byType(ChangeChip));
      await tester.pump();
      for (var frame = 0; frame < 15; frame++) {
        expect(find.byType(SkeletonShimmer), findsNothing, reason: '$frame');
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(MarketChartLoading), findsOneWidget);
      expect(_inSheet(find.text('Carregando...')), findsOneWidget);

      loading = false;
      ProviderScope.containerOf(
        tester.element(find.byType(PortfolioHistorySheet)),
      ).invalidate(portfolioHistoryProvider);
      await tester.pump();

      /// How much shows of the chart state that [finder] finds: the product
      /// of the fades inside the switcher above it, 0 when it is gone. The
      /// dimming of a loading chart is a fade too.
      double opacityOf(Finder finder) {
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

      for (var frame = 0; frame < 30; frame++) {
        expect(find.byType(SkeletonShimmer), findsNothing, reason: '$frame');
        final pill = opacityOf(find.byType(MarketChartLoading));
        final chart = opacityOf(find.byType(MarketChart));
        expect(
          pill == 0 || chart == 0,
          isTrue,
          reason: 'frame $frame: $pill, $chart',
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(MarketChartLoading), findsNothing);
      expect(opacityOf(find.byType(MarketChart)), 1);
    });

    testWidgets('a period filter loads the other period', (tester) async {
      await _open(tester, _launcher());

      await tester.tap(_inSheet(find.text(MarketPeriod.week.label)));
      await tester.pumpAndSettle();

      // 2000 → 1940: −3% over 7 days.
      expect(_inSheet(find.text('1.940,00')), findsOneWidget);
      expect(_inSheet(find.text('−3,00%')), findsOneWidget);
    });

    testWidgets('a scrub shows the value under the finger', (tester) async {
      await _open(tester, _launcher());

      final chart = tester.getRect(find.byType(LineChart));
      final gesture = await tester.startGesture(
        chart.centerLeft + const Offset(1, 0),
      );
      await tester.pump();
      expect(_inSheet(find.text('1.000,00')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_inSheet(find.text('1.230,00')), findsOneWidget);
    });

    testWidgets('a hidden balance masks the money and keeps the change', (
      tester,
    ) async {
      await _open(tester, _launcher(hidden: true));

      expect(_inSheet(find.text('1.230,00')), findsNothing);
      expect(_inSheet(find.text('•••••')), findsOneWidget);
      expect(_inSheet(find.text('+23,00%')), findsOneWidget);
    });

    testWidgets('a wallet without holdings shows the unavailable state', (
      tester,
    ) async {
      await _open(
        tester,
        _launcher(history: (_) => const AsyncValue.data(null)),
      );

      expect(find.byType(MarketChartUnavailable), findsOneWidget);
      expect(find.byType(MarketChart), findsNothing);
    });
  });
}
