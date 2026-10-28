import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/balance_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

const _amount = BalanceAmount(
  prefix: 'R\$',
  digits: '8.908,47',
  value: 8908.47,
);

Widget _hero({
  required bool hidden,
  AsyncValue<BalanceAmount?> amount = const AsyncData(_amount),
  AsyncValue<double?> variation = const AsyncData(-0.07),
  VoidCallback? onToggle,
  VoidCallback? onCycle,
}) => wrapForTest(
  Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: BalanceHeroView(
        amount: amount,
        mode: 'fiat',
        isHidden: hidden,
        variation: variation,
        onToggleVisibility: onToggle ?? () {},
        onCycleMode: onCycle ?? () {},
      ),
    ),
  ),
);

void main() {
  group('BalanceHeroView', () {
    testWidgets('shows the muted currency and the final digits on the first '
        'frame', (tester) async {
      await tester.pumpWidget(_hero(hidden: false));

      // No count-up: the first frame shows the final value.
      expect(find.text('8.908,47'), findsOneWidget);
      final currency = tester.widget<Text>(find.text('R\$'));
      expect(currency.style?.color, AppExtraColors.dark.textSecondary);
    });

    testWidgets('a hidden balance shows a fixed mask and a hidden label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_hero(hidden: true));

      expect(find.text(balanceMask), findsOneWidget);
      expect(find.text('8.908,47'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Saldo oculto')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('8.908')), findsNothing);
      semantics.dispose();
    });

    testWidgets('the visible balance reads as one sentence', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_hero(hidden: false));

      expect(
        find.bySemanticsLabel('Minha Carteira, R\$ 8.908,47'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('the visibility toggle cross-fades digits and mask', (
      tester,
    ) async {
      await tester.pumpWidget(_hero(hidden: false));
      await tester.pumpWidget(_hero(hidden: true));
      await tester.pump(Motion.durationFast ~/ 2);

      expect(find.text('8.908,47'), findsOneWidget);
      expect(find.text(balanceMask), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('8.908,47'), findsNothing);
      expect(find.text(balanceMask), findsOneWidget);
    });

    testWidgets('reduced motion toggles the mask at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_hero(hidden: false));
      await tester.pumpWidget(_hero(hidden: true));
      await tester.pump();

      expect(find.text('8.908,47'), findsNothing);
      expect(find.text(balanceMask), findsOneWidget);
    });

    testWidgets('a balance change animates only the digits', (tester) async {
      await tester.pumpWidget(_hero(hidden: false));
      await tester.pumpWidget(
        _hero(
          hidden: false,
          amount: const AsyncData(
            BalanceAmount(prefix: 'R\$', digits: '8.910,00', value: 8910),
          ),
        ),
      );
      await tester.pump(Motion.durationBase ~/ 2);

      expect(find.text('8.908,47'), findsOneWidget);
      expect(find.text('8.910,00'), findsOneWidget);
      // The currency symbol does not change.
      expect(find.text('R\$'), findsOneWidget);

      await tester.pump(Motion.numberChangeInterval);
    });

    testWidgets('a change that rounds to zero hides the chip', (tester) async {
      await tester.pumpWidget(
        _hero(hidden: false, variation: const AsyncData(0.001)),
      );
      expect(find.byType(ChangeChip), findsNothing);
    });

    testWidgets('screen readers can open the pending Pix badge', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: BalanceHeroView(
              amount: const AsyncData(_amount),
              mode: 'fiat',
              isHidden: false,
              variation: const AsyncData(null),
              onToggleVisibility: () {},
              onCycleMode: () {},
              showPendingPix: true,
              onPendingPixTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pump(Motion.durationSlow * 4);

      final badge = find.bySemanticsLabel('Depósitos em andamento');
      expect(
        tester.getSemantics(badge),
        matchesSemantics(
          label: 'Depósitos em andamento',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the eye button and the amount run their actions', (
      tester,
    ) async {
      var toggles = 0;
      var cycles = 0;
      await tester.pumpWidget(
        _hero(
          hidden: false,
          onToggle: () => toggles++,
          onCycle: () => cycles++,
        ),
      );

      await tester.tap(find.byTooltip('Ocultar saldo'));
      await tester.tap(find.text('8.908,47'));
      expect(toggles, 1);
      expect(cycles, 1);
    });

    testWidgets('loading shows a skeleton, then cross-fades to the value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hero(
          hidden: false,
          amount: const AsyncLoading(),
          variation: const AsyncLoading(),
        ),
      );
      expect(find.text('8.908,47'), findsNothing);

      await tester.pumpWidget(_hero(hidden: false));
      await tester.pump(Motion.durationBase ~/ 2);
      // The state switcher fades the content keyed 'data' in.
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('data')),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));

      await tester.pump(Motion.durationBase);
    });
  });

  group('Count-up after a tap', () {
    final brl = NumberFormat('#,##0.00', 'pt');

    BalanceAmount fiat(double value) => BalanceAmount(
      prefix: 'R\$',
      digits: brl.format(value),
      value: value,
      format: brl.format,
    );

    BalanceAmount sats(int value) => BalanceAmount(
      digits: SatsInputFormatter.formatValue(value),
      suffix: 'sats',
      value: value.toDouble(),
      format: (count) => SatsInputFormatter.formatValue(count.round()),
    );

    Widget hero({
      required Object mode,
      required AsyncValue<BalanceAmount?> amount,
      bool hidden = false,
    }) => wrapForTest(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: BalanceHeroView(
            amount: amount,
            mode: mode,
            isHidden: hidden,
            variation: const AsyncData(null),
            onToggleVisibility: () {},
            onCycleMode: () {},
          ),
        ),
      ),
    );

    Future<void> tapAmountAndShowSats(WidgetTester tester) async {
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47))),
      );
      await tester.tap(find.text('8.908,47'));
      // The provider switches the unit after the tap.
      await tester.pumpWidget(
        hero(mode: 'sats', amount: AsyncData(sats(2075700))),
      );
    }

    testWidgets('a tap on the amount counts the new unit up from zero', (
      tester,
    ) async {
      await tapAmountAndShowSats(tester);
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      await tester.pump(Motion.durationCountUp ~/ 4);
      final counting = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .map((data) => int.tryParse(data.replaceAll('.', '')))
          .whereType<int>()
          .where((value) => value > 0 && value < 2075700);
      expect(counting, isNotEmpty);

      await tester.pump(Motion.durationCountUp);
      await tester.pump();
      expect(find.text('2.075.700'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('the figure comes into focus in the first half', (
      tester,
    ) async {
      await tapAmountAndShowSats(tester);
      await tester.pump();
      final start = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
      expect(start.enabled, isTrue);

      await tester.pump(Motion.durationCountUp * 0.6);
      final later = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
      expect(later.enabled, isFalse);

      await tester.pumpAndSettle();
    });

    testWidgets('the row keeps the final width while counting', (tester) async {
      await tapAmountAndShowSats(tester);
      await tester.pump(Motion.durationCountUp ~/ 4);
      final counting = tester.getSize(find.byKey(const ValueKey('data')));

      await tester.pumpAndSettle();
      final settled = tester.getSize(find.byKey(const ValueKey('data')));
      expect(counting.width, closeTo(settled.width, 0.5));
    });

    testWidgets('screen readers get the final figure during the count', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tapAmountAndShowSats(tester);
      await tester.pump(Motion.durationCountUp ~/ 4);

      expect(
        find.bySemanticsLabel('Minha Carteira, 2.075.700 sats'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      semantics.dispose();
    });

    testWidgets('a reveal counts the balance up', (tester) async {
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47)), hidden: true),
      );
      await tester.tap(find.byTooltip('Mostrar saldo'));
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47))),
      );
      await tester.pump();
      expect(find.text('0,00'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('8.908,47'), findsOneWidget);
    });

    testWidgets('a price update does not count up', (tester) async {
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47))),
      );
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8910))),
      );
      await tester.pump();

      expect(find.text('0,00'), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      await tester.pump(Motion.numberChangeInterval);
    });

    testWidgets('a late figure after a tap shows without a count-up', (
      tester,
    ) async {
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47))),
      );
      await tester.tap(find.text('8.908,47'));
      await tester.pumpWidget(hero(mode: 'sats', amount: const AsyncLoading()));
      await tester.pump(Motion.durationCountUp * 3);

      await tester.pumpWidget(
        hero(mode: 'sats', amount: AsyncData(sats(2075700))),
      );
      await tester.pump();
      expect(find.text('0'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion shows the new unit at once', (tester) async {
      reduceMotion(tester);
      await tapAmountAndShowSats(tester);
      await tester.pump();

      expect(find.text('2.075.700'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('a press sinks the amount a little', (tester) async {
      await tester.pumpWidget(
        hero(mode: 'fiat', amount: AsyncData(fiat(8908.47))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('8.908,47')),
      );
      await tester.pump(Motion.durationPress);

      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byType(BalanceHeroView),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        Motion.pressScale,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('ChangeChip', () {
    Widget chip(double percentage) => wrapForTest(
      Scaffold(
        body: Center(child: ChangeChip(percentage: percentage)),
      ),
    );

    double turns(WidgetTester tester) =>
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

    testWidgets('shows sign and locale decimals', (tester) async {
      await tester.pumpWidget(chip(2.25));
      expect(find.text('+2,25%'), findsOneWidget);

      await tester.pumpWidget(chip(-0.62));
      await tester.pump(Motion.numberChangeInterval);
      await tester.pump(Motion.durationBase);
      expect(find.text('−0,62%'), findsOneWidget);
    });

    testWidgets('a change that rounds to zero shows as no change', (
      tester,
    ) async {
      await tester.pumpWidget(chip(0.001));
      expect(find.text('0,00%'), findsOneWidget);
      expect(find.byType(AnimatedRotation), findsNothing);
    });

    testWidgets('no change shows no arrow and no sign', (tester) async {
      await tester.pumpWidget(chip(0));
      expect(find.text('0,00%'), findsOneWidget);
      expect(find.byType(AnimatedRotation), findsNothing);
    });

    testWidgets('a direction flip turns the arrow', (tester) async {
      await tester.pumpWidget(chip(1));
      expect(turns(tester), 0);

      await tester.pumpWidget(chip(-1));
      expect(turns(tester), 0.5);

      await tester.pump(Motion.numberChangeInterval);
    });
  });
}
