import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  late List<FeeSpeed> changes;

  /// The selector with [selected], in Portuguese, at the rates 2, 5 and 9
  /// sat/vB. A change selects the new speed, as the send form does.
  Future<void> pump(
    WidgetTester tester, {
    FeeSpeed? selected = FeeSpeed.medium,
    bool withLow = true,
    int? lowRate = 2,
  }) async {
    changes = [];
    var current = selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) => FeeSpeedSelector(
                selectedSpeed: current,
                lowFeeLoading: withLow,
                onSpeedChanged: (speed) {
                  changes.add(speed);
                  setState(() => current = speed);
                },
                lowFeeSatPerVByte: lowRate,
                mediumFeeSatPerVByte: 5,
                fastFeeSatPerVByte: 9,
              ),
            ),
          ),
        ),
      ),
    );
    // A loading rate shimmers without end.
    if (lowRate == null) {
      await tester.pump(const Duration(seconds: 1));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Rect lens(WidgetTester tester) => tester.getRect(find.byType(GlassLens));

  double lensOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(
          of: find.byType(GlassLens),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  /// The segment box of the speed titled [title].
  Rect segment(WidgetTester tester, String title) => tester.getRect(
    find.ancestor(of: find.text(title), matching: find.byType(SizedBox)).last,
  );

  testWidgets('each speed shows its rate and wait on a glass track, with '
      'the lens on the selected one', (tester) async {
    await pump(tester);

    for (final text in [
      t.wallet_fee_economic,
      t.wallet_fee_normal,
      t.wallet_fee_fast,
      '2 sat/vB',
      '5 sat/vB',
      '9 sat/vB',
      t.wallet_fee_economic_eta,
      t.wallet_fee_normal_eta,
      t.wallet_fee_fast_eta,
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    final control = tester.widget<GlassSegmentedControl<FeeSpeed>>(
      find.byType(GlassSegmentedControl<FeeSpeed>),
    );
    expect(control.expand, isTrue);
    expect(control.borderRadius, FeeSpeedSelector.radius);
    expect(
      lens(tester),
      rectMoreOrLessEquals(segment(tester, t.wallet_fee_normal)),
    );
  });

  testWidgets('the three speeds share the track in equal parts', (
    tester,
  ) async {
    await pump(tester);

    final widths = [
      for (final title in [
        t.wallet_fee_economic,
        t.wallet_fee_normal,
        t.wallet_fee_fast,
      ])
        segment(tester, title).width,
    ];
    expect(widths, everyElement(moreOrLessEquals(widths.first)));
  });

  testWidgets('a tap or a drag selects a speed', (tester) async {
    await pump(tester);

    await tester.tap(find.text(t.wallet_fee_fast));
    await tester.pumpAndSettle();
    expect(changes, [FeeSpeed.fast]);
    expect(
      lens(tester),
      rectMoreOrLessEquals(segment(tester, t.wallet_fee_fast)),
    );

    final from = segment(tester, t.wallet_fee_fast).center;
    final to = segment(tester, t.wallet_fee_economic).center;
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, [FeeSpeed.fast, FeeSpeed.low]);
    expect(
      lens(tester),
      rectMoreOrLessEquals(segment(tester, t.wallet_fee_economic)),
    );
  });

  testWidgets('with no speed selected, the lens hides', (tester) async {
    await pump(tester, selected: null);

    expect(lensOpacity(tester), 0);

    await tester.tap(find.text(t.wallet_fee_normal));
    await tester.pumpAndSettle();
    expect(changes, [FeeSpeed.medium]);
    expect(lensOpacity(tester), 1);
  });

  testWidgets('a rate that still loads shows a skeleton, and its speed '
      'takes no tap', (tester) async {
    await pump(tester, lowRate: null);

    expect(find.byType(SkeletonBox), findsOneWidget);
    expect(find.text('2 sat/vB'), findsNothing);

    await tester.tap(find.text(t.wallet_fee_economic));
    await tester.pump(const Duration(seconds: 1));
    expect(changes, isEmpty);
  });

  testWidgets('without the economic speed, two speeds share the track', (
    tester,
  ) async {
    await pump(tester, withLow: false);

    expect(find.text(t.wallet_fee_economic), findsNothing);
    expect(
      segment(tester, t.wallet_fee_normal).width,
      moreOrLessEquals(segment(tester, t.wallet_fee_fast).width),
    );
  });

  testWidgets('screen readers hear the speed, its rate and its wait', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.text(t.wallet_fee_normal)),
      matchesSemantics(
        label: '${t.wallet_fee_normal}, 5 sat/vB, ${t.wallet_fee_normal_eta}',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
