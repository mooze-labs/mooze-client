import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/custom_fee_rate_option.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_slider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../../../swap/presentation/fixed_fee_provider.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  late List<double> changes;

  /// Clears the rate, as a tap on a speed does.
  late void Function() clear;

  /// The option with [rate], in Portuguese. A change sets the new rate, as
  /// the send form does. The fee rates are economic 2, normal 5 and fast
  /// 9 sat/vB.
  Future<void> pump(
    WidgetTester tester, {
    double? rate,
    bool reducedMotion = false,
  }) async {
    changes = [];
    var current = rate;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                clear = () => setState(() => current = null);
                return CustomFeeRateOption(
                  rate: current,
                  estimate: fixedBitcoinFees(),
                  onChanged: (next) {
                    changes.add(next);
                    setState(() => current = next);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  Future<void> tapStep(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pump();
  }

  testWidgets('offers a custom rate, and a tap starts from the Normal rate', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(t.wallet_fee_custom_choose), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();

    expect(changes, [5]);
    expect(field(tester), '5');
    expect(find.text('sat/vB'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('the keyboard has a decimal mark', (tester) async {
    await pump(tester, rate: 5);

    final keyboard = tester
        .widget<TextField>(find.byType(TextField))
        .keyboardType;
    expect(keyboard, const TextInputType.numberWithOptions(decimal: true));
  });

  testWidgets('a rate below 1 sat/vB takes a comma or a point', (tester) async {
    await pump(tester, rate: 5);

    await tester.enterText(find.byType(TextField), '0,3');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '0.7');
    await tester.pump();

    expect(changes, [0.3, 0.7]);
  });

  testWidgets('the rate has one decimal and four digits at most', (
    tester,
  ) async {
    await pump(tester, rate: 5);

    await tester.enterText(find.byType(TextField), '1,2');
    await tester.pump();
    // A second decimal, a second mark, a fifth digit, or a letter does
    // not go in.
    for (final text in ['1,25', '1,2,', '12345', '1a']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(field(tester), '1,2', reason: text);
    }
    expect(changes, [1.2]);
  });

  testWidgets('the rate does not go below 0.1 sat/vB', (tester) async {
    await pump(tester, rate: 0.1);

    expect(button(tester, t.wallet_fee_custom_decrease).onPressed, isNull);

    // "0" and "0," are still on the way to a rate: they change nothing.
    for (final text in ['0', '0,', '0,0']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }
    expect(changes, isEmpty);

    // Leaving the unfinished field shows the rate again.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(field(tester), '0,1');
  });

  testWidgets('the buttons step tenths below 1 sat/vB and whole rates from '
      'there', (tester) async {
    await pump(tester, rate: 0.8);

    await tapStep(tester, t.wallet_fee_custom_increase);
    await tapStep(tester, t.wallet_fee_custom_increase);
    await tapStep(tester, t.wallet_fee_custom_increase);
    await tapStep(tester, t.wallet_fee_custom_decrease);
    await tapStep(tester, t.wallet_fee_custom_decrease);
    await tapStep(tester, t.wallet_fee_custom_decrease);

    expect(changes, [0.9, 1, 2, 1, 0.9, 0.8]);
    expect(field(tester), '0,8');
  });

  testWidgets('a broken rate steps to the whole rates around it', (
    tester,
  ) async {
    await pump(tester, rate: 1.5);
    await tapStep(tester, t.wallet_fee_custom_increase);
    expect(changes, [2]);

    await pump(tester, rate: 1.5);
    await tapStep(tester, t.wallet_fee_custom_decrease);
    expect(changes, [1]);
  });

  testWidgets('the slider sweeps from 0.1 sat/vB to twice the Fast rate, '
      'and the rate applies on release', (tester) async {
    await pump(tester, rate: 5);
    final slider = find.byType(Slider);
    final left = tester.getTopLeft(slider);
    final size = tester.getSize(slider);
    final y = left.dy + size.height / 2;

    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveTo(Offset(left.dx - 40, y));
    await tester.pump();
    // The field follows the thumb; the rate waits for the release.
    expect(field(tester), '0,1');
    expect(changes, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(changes, [0.1]);

    await tester.drag(slider, Offset(size.width + 80, 0));
    await tester.pump();
    expect(changes.last, 18);
  });

  testWidgets('the slider gives the rates below 1 sat/vB room', (tester) async {
    await pump(tester, rate: 1);

    // On a log scale from 0.1 to 18 sat/vB, 1 sat/vB sits at 44% of the
    // slider, so the rates below it get almost half of it.
    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(0.4));
  });

  testWidgets('tells the expected wait from the network rates', (tester) async {
    for (final (rate, eta) in [
      (2.0, t.wallet_fee_economic_eta),
      (4.5, t.wallet_fee_economic_eta),
      (5.0, t.wallet_fee_normal_eta),
      (9.0, t.wallet_fee_fast_eta),
      (18.0, t.wallet_fee_fast_eta),
    ]) {
      await pump(tester, rate: rate);
      expect(
        find.text(t.wallet_fee_custom_eta(eta)),
        findsOneWidget,
        reason: '$rate sat/vB',
      );
    }
  });

  testWidgets('warns that a rate below 1 sat/vB may be refused', (
    tester,
  ) async {
    await pump(tester, rate: 0.5);

    expect(find.text(t.wallet_fee_custom_below_relay), findsOneWidget);
  });

  testWidgets('warns below the Economic rate', (tester) async {
    await pump(tester, rate: 1.5);

    expect(find.text(t.wallet_fee_custom_below_low(2)), findsOneWidget);
  });

  testWidgets('warns above twice the Fast rate', (tester) async {
    await pump(tester, rate: 18.1);

    expect(find.text(t.wallet_fee_custom_above_fast(9)), findsOneWidget);
  });

  group('on Liquid Glass', () {
    /// The lens that marks the selected rate: the one as wide as the row.
    Finder rowLens() => find.byWidgetPredicate(
      (widget) =>
          widget is GlassLens &&
          widget.borderRadius != const BorderRadius.all(Radius.circular(999)),
    );

    double rowLensOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: rowLens(), matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    testWidgets('the row is the glass track of the speeds, and a selected '
        'rate fades a lens in on its title line', (tester) async {
      await pump(tester);

      final track = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
      expect(track.borderRadius, FeeSpeedSelector.radius);
      expect(track.blurBackdrop, isFalse);
      expect(rowLensOpacity(tester), 0);

      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // On the way in, the lens is still faint.
      expect(rowLensOpacity(tester), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(rowLensOpacity(tester), 1);
      final lens = tester.getRect(rowLens());
      final row = tester.getRect(find.byType(LiquidGlass));
      // The lens marks the title line, inside the inset, as it marks a
      // selected speed.
      expect(lens.width, moreOrLessEquals(row.width - 6));
      expect(lens.top, moreOrLessEquals(row.top + 3));
      expect(lens.height, moreOrLessEquals(48));
      // The open row sits on the glass itself, not on a second layer.
      expect(
        tester.getRect(find.byType(TextField)).top,
        greaterThanOrEqualTo(lens.bottom),
      );
    });

    testWidgets('the row opens like a drawer: it grows, and its content '
        'keeps its size on the way', (tester) async {
      await pump(tester);
      final closed = tester.getSize(find.byType(LiquidGlass)).height;

      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final growing = tester.getSize(find.byType(LiquidGlass)).height;
      final field = tester.getSize(find.byType(TextField));
      final slider = tester.getSize(find.byType(GlassSlider));

      await tester.pumpAndSettle();
      final open = tester.getSize(find.byType(LiquidGlass)).height;
      expect(growing, inExclusiveRange(closed, open));
      expect(tester.getSize(find.byType(TextField)), field);
      expect(tester.getSize(find.byType(GlassSlider)), slider);
    });

    testWidgets('a speed that clears the rate closes the row on its last '
        'rate, which takes no touch on the way', (tester) async {
      await pump(tester, rate: 5);

      clear();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(field(tester), '5');
      await tester.tap(
        find.byTooltip(t.wallet_fee_custom_increase),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(changes, isEmpty);

      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text(t.wallet_fee_custom_choose), findsOneWidget);
    });

    testWidgets('with reduced motion, the row opens at once', (tester) async {
      await pump(tester, reducedMotion: true);

      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pump();

      expect(field(tester), '5');
      final open = tester.getSize(find.byType(LiquidGlass)).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(LiquidGlass)).height, open);
    });

    testWidgets('the rate sits in a well cut into the lens', (tester) async {
      await pump(tester, rate: 5);

      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      final context = tester.element(find.byType(TextField));
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, GlassStyle.of(context).groove);
    });

    testWidgets('dots on the slider mark the Economic, Normal and Fast '
        'rates', (tester) async {
      await pump(tester, rate: 5);

      // On the log scale from 0.1 to 18 sat/vB.
      double position(double rate) => math.log(rate / 0.1) / math.log(18 / 0.1);
      final marks = tester.widget<GlassSlider>(find.byType(GlassSlider)).marks;
      expect(marks, hasLength(3));
      for (final (mark, rate) in [
        (marks[0], 2.0),
        (marks[1], 5.0),
        (marks[2], 9.0),
      ]) {
        expect(mark, moreOrLessEquals(position(rate)), reason: '$rate');
      }
    });

    testWidgets('a warning fills the slider in the warning color', (
      tester,
    ) async {
      Color? fill() =>
          tester.widget<GlassSlider>(find.byType(GlassSlider)).activeColor;

      await pump(tester, rate: 5);
      final context = tester.element(find.byType(GlassSlider));
      expect(fill(), context.colors.textPrimary);

      for (final rate in [0.5, 1.5, 18.1]) {
        await pump(tester, rate: rate);
        expect(
          fill(),
          pixToneColor(context, PixTone.warning),
          reason: '$rate sat/vB',
        );
      }
    });

    testWidgets('the step buttons are glass lenses that keep a 48 pt '
        'target', (tester) async {
      await pump(tester, rate: 5);

      for (final tooltip in [
        t.wallet_fee_custom_decrease,
        t.wallet_fee_custom_increase,
      ]) {
        final button = find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        );
        expect(tester.getSize(button), const Size(48, 48));
        expect(
          find.descendant(of: button, matching: find.byType(GlassLens)),
          findsOneWidget,
        );
      }
    });
  });

  group('the chevron', () {
    double turns(WidgetTester tester) =>
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

    testWidgets('closes the row to one line with the rate, and keeps the '
        'rate and its warning', (tester) async {
      await pump(tester, rate: 0.3);
      expect(turns(tester), 0.5);

      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(GlassSlider), findsNothing);
      expect(find.text('0,3 sat/vB'), findsOneWidget);
      expect(find.text(t.wallet_fee_custom_below_relay), findsOneWidget);
      expect(turns(tester), 0);
      expect(changes, isEmpty);
    });

    testWidgets('opens the row again on the same rate', (tester) async {
      await pump(tester, rate: 0.3);
      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pumpAndSettle();

      await tester.tap(find.text('0,3 sat/vB'));
      await tester.pumpAndSettle();

      expect(field(tester), '0,3');
      expect(find.byType(GlassSlider), findsOneWidget);
      expect(find.text('0,3 sat/vB'), findsNothing);
      expect(turns(tester), 0.5);
      expect(changes, isEmpty);
    });

    testWidgets('points down to open the offer', (tester) async {
      await pump(tester);

      expect(turns(tester), 0);
      expect(find.text(t.wallet_fee_custom_choose), findsOneWidget);
    });

    testWidgets('closing takes the keyboard away at once', (tester) async {
      await pump(tester, rate: 5);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      // The keyboard goes with the tap, not when the row ends closing.
      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('screen readers hear whether the row is open', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, rate: 5);
      expect(
        tester.getSemantics(find.text(t.wallet_fee_custom)),
        isSemantics(
          isButton: true,
          isSelected: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );

      await tester.tap(find.text(t.wallet_fee_custom));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text(t.wallet_fee_custom)),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      handle.dispose();
    });
  });
}
