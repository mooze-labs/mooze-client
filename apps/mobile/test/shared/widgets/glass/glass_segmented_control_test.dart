import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

const _units = [
  GlassSegment(value: 'asset', label: 'BTC L2'),
  GlassSegment(value: 'sats', label: 'sats'),
  GlassSegment(value: 'fiat', label: r'R$'),
];

void main() {
  late List<String> changes;
  late List<Object?> haptics;
  late ValueNotifier<List<GlassSegment<String>>> segments;
  late void Function() selectNone;
  late void Function() rebuild;

  /// The control with [selected]. A change selects the new value, as the
  /// send and receive screens do.
  Future<void> pump(
    WidgetTester tester, {
    String? selected = 'asset',
    bool reducedMotion = false,
    List<GlassSegment<String>> units = _units,
    bool expand = false,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(999)),
    double width = 360,
  }) async {
    changes = [];
    haptics = [];
    segments = ValueNotifier(units);
    addTearDown(segments.dispose);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    var value = selected;
    selectNone = () => value = null;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: expand ? width : null,
              child: ValueListenableBuilder(
                valueListenable: segments,
                builder: (context, list, _) => StatefulBuilder(
                  builder: (context, setState) {
                    rebuild = () => setState(() {});
                    return GlassSegmentedControl<String>(
                      segments: list,
                      selected: value,
                      expand: expand,
                      borderRadius: borderRadius,
                      onChanged: (next) {
                        changes.add(next);
                        setState(() => value = next);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  Rect segment(WidgetTester tester, String label) => tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(SizedBox)).first,
  );

  testWidgets('the lens marks the selected segment, with no tinted pill', (
    tester,
  ) async {
    await pump(tester, selected: 'sats');

    expect(find.byType(GlassLens), findsOneWidget);
    expect(lens(tester), segment(tester, 'sats'));
    // The track is Liquid Glass, as the navigation bar.
    expect(find.byType(LiquidGlass), findsOneWidget);
  });

  testWidgets('a tap selects the segment, and the lens slides there and '
      'stretches on the way', (tester) async {
    await pump(tester);

    await tester.tap(find.text(r'R$'));
    await tester.pump();
    expect(changes, ['fiat']);

    // On the way, the lens stretches: it widens and flattens.
    await tester.pump(const Duration(milliseconds: 200));
    expect(lens(tester).height, lessThan(segment(tester, 'sats').height));

    await tester.pumpAndSettle();
    expect(lens(tester), segment(tester, r'R$'));
  });

  testWidgets('the segments keep their width when the selection changes', (
    tester,
  ) async {
    await pump(tester);
    final before = [
      for (final unit in _units) segment(tester, unit.label).width,
    ];

    await tester.tap(find.text('sats'));
    await tester.pumpAndSettle();

    expect([
      for (final unit in _units) segment(tester, unit.label).width,
    ], before);
  });

  testWidgets('a drag moves the lens with the finger, clicks on each '
      'segment it reaches, and selects on release', (tester) async {
    await pump(tester);
    final start = segment(tester, 'BTC L2').center;
    final end = segment(tester, r'R$').center;

    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final steps = 10;
    final step = (end.dx - start.dx - 20) / steps;
    double? lastLeft;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(step, 0));
      await tester.pump();
      final left = lens(tester).left;
      if (lastLeft != null) expect(left, greaterThanOrEqualTo(lastLeft));
      lastLeft = left;
    }
    // The value changes once, on release.
    expect(changes, isEmpty);
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
    ]);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, ['fiat']);
    expect(lens(tester), segment(tester, r'R$'));
  });

  testWidgets('a short drag springs back and keeps the value', (tester) async {
    await pump(tester, selected: 'sats');

    final gesture = await tester.startGesture(segment(tester, 'sats').center);
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(6, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(lens(tester), segment(tester, 'sats'));
  });

  testWidgets('a flick moves on to the next segment', (tester) async {
    await pump(tester);

    // The drag alone ends short of halfway. The speed carries it on.
    await tester.fling(find.text('BTC L2'), const Offset(60, 0), 500);
    await tester.pumpAndSettle();

    expect(changes, ['sats']);
  });

  testWidgets('past the first segment, the lens presses against the end '
      'and stays inside the track', (tester) async {
    await pump(tester);
    final track = tester.getRect(find.byType(LiquidGlass));

    final gesture = await tester.startGesture(segment(tester, 'BTC L2').center);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
    }
    expect(lens(tester).left, greaterThanOrEqualTo(track.left));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(lens(tester), segment(tester, 'BTC L2'));
  });

  testWidgets('with reduced motion, the lens jumps to a tapped segment', (
    tester,
  ) async {
    await pump(tester, reducedMotion: true);

    await tester.tap(find.text(r'R$'));
    await tester.pump();

    expect(lens(tester), segment(tester, r'R$'));
  });

  testWidgets('new segments, for another asset, put the lens on the '
      'selected one at once', (tester) async {
    await pump(tester, selected: 'fiat');

    segments.value = [_units[0], _units[2]];
    await tester.pump();

    expect(find.text('sats'), findsNothing);
    expect(lens(tester), segment(tester, r'R$'));
  });

  testWidgets('screen readers hear each segment as a button in a group, '
      'and the selected one as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, selected: 'sats');

    expect(
      tester.getSemantics(find.text('sats')),
      matchesSemantics(
        label: 'sats',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text(r'R$')),
      matchesSemantics(
        label: r'R$',
        isButton: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  group('with no segment selected', () {
    testWidgets('the lens hides, and a tap brings it back on the tapped '
        'segment', (tester) async {
      await pump(tester, selected: null);

      expect(lensOpacity(tester), 0);
      expect(
        tester.getSemantics(find.text('sats')),
        isNot(matchesSemantics(isSelected: true)),
      );

      await tester.tap(find.text(r'R$'));
      await tester.pump();
      expect(changes, ['fiat']);
      await tester.pumpAndSettle();

      expect(lensOpacity(tester), 1);
      expect(lens(tester), segment(tester, r'R$'));
    });

    testWidgets('a selection cleared by the parent fades the lens out where '
        'it was', (tester) async {
      await pump(tester, selected: 'sats');

      selectNone();
      rebuild();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fading = lensOpacity(tester);
      expect(fading, inExclusiveRange(0, 1));
      expect(lens(tester).center.dx, segment(tester, 'sats').center.dx);

      await tester.pumpAndSettle();
      expect(lensOpacity(tester), 0);
    });

    testWidgets('a drag brings the lens up under the finger, and selects on '
        'release', (tester) async {
      await pump(tester, selected: null);
      final start = segment(tester, r'R$').center;

      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-2, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(lensOpacity(tester), 1);
      expect(
        lens(tester).center.dx,
        moreOrLessEquals(start.dx - 22, epsilon: 1),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes, ['fiat']);
      expect(lens(tester), segment(tester, r'R$'));
    });

    testWidgets('with reduced motion, the lens shows and hides at once', (
      tester,
    ) async {
      await pump(tester, selected: 'sats', reducedMotion: true);

      selectNone();
      rebuild();
      await tester.pump();
      expect(lensOpacity(tester), 0);

      await tester.tap(find.text('BTC L2'));
      await tester.pump();
      expect(lensOpacity(tester), 1);
      expect(lens(tester), segment(tester, 'BTC L2'));
    });
  });

  group('a disabled segment', () {
    const units = [
      GlassSegment(value: 'asset', label: 'BTC L2'),
      GlassSegment(value: 'sats', label: 'sats'),
      GlassSegment(value: 'fiat', label: r'R$', enabled: false),
    ];

    testWidgets('takes no tap, and screen readers hear it as disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, units: units);

      await tester.tap(find.text(r'R$'));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
      expect(lens(tester), segment(tester, 'BTC L2'));
      expect(
        tester.getSemantics(find.text(r'R$')),
        matchesSemantics(
          label: r'R$',
          isButton: true,
          hasEnabledState: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('springs a drag released over it back to the selected one', (
      tester,
    ) async {
      await pump(tester, selected: 'sats', units: units);
      final start = segment(tester, 'sats').center;
      final end = segment(tester, r'R$').center;

      final gesture = await tester.startGesture(start);
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(Offset((end.dx - start.dx) / 8 + 3, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Straight back, not by way of the disabled segment.
      expect(lens(tester).center.dx, lessThan(end.dx - 20));

      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(lens(tester), segment(tester, 'sats'));
    });
  });

  testWidgets('expanded segments share the width in equal parts, and the '
      'tallest one sets the height of the row', (tester) async {
    await pump(
      tester,
      expand: true,
      width: 360,
      units: [
        const GlassSegment(value: 'asset', label: 'BTC L2'),
        GlassSegment(
          value: 'sats',
          label: 'sats, 3 lines',
          builder: (context, selected) =>
              const Column(children: [Text('a'), Text('b'), Text('c')]),
        ),
        const GlassSegment(value: 'fiat', label: r'R$'),
      ],
    );

    final track = tester.getRect(find.byType(LiquidGlass));
    expect(track.width, 360);
    final widths = [
      segment(tester, 'BTC L2').width,
      tester
          .getRect(
            find
                .ancestor(of: find.text('a'), matching: find.byType(SizedBox))
                .first,
          )
          .width,
      segment(tester, r'R$').width,
    ];
    const inner = 360 - 2 * GlassSegmentedControl.inset;
    expect(widths, everyElement(moreOrLessEquals(inner / 3)));
    // Three lines are taller than one: every segment and the lens take the
    // height of the tallest.
    final height = segment(tester, 'BTC L2').height;
    expect(height, greaterThan(GlassSegmentedControl.segmentHeight));
    expect(segment(tester, r'R$').height, height);
    expect(lens(tester).height, height);
  });

  testWidgets('a segment builds its own content, told whether it is under '
      'the lens', (tester) async {
    final seen = <String, bool>{};
    GlassSegment<String> built(String value) => GlassSegment(
      value: value,
      label: value,
      builder: (context, selected) {
        seen[value] = selected;
        return Text('[$value]');
      },
    );
    await pump(tester, selected: 'b', units: [built('a'), built('b')]);

    expect(find.text('[a]'), findsOneWidget);
    expect(seen, {'a': false, 'b': true});

    await tester.tap(find.text('[a]'));
    await tester.pumpAndSettle();
    expect(changes, ['a']);
    expect(seen, {'a': true, 'b': false});
  });

  testWidgets('the lens keeps the corners of the track, less the inset', (
    tester,
  ) async {
    await pump(
      tester,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
    );

    expect(
      tester.widget<LiquidGlass>(find.byType(LiquidGlass)).borderRadius,
      const BorderRadius.all(Radius.circular(24)),
    );
    expect(
      tester.widget<GlassLens>(find.byType(GlassLens)).borderRadius,
      const BorderRadius.all(Radius.circular(24 - GlassSegmentedControl.inset)),
    );
  });
}
