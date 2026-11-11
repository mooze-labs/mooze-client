import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_slider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

void main() {
  late List<double> values;
  late List<Object?> haptics;

  /// The slider at [value], 300 pt wide, with [marks]. A change moves it,
  /// as a parent does.
  Future<void> pump(
    WidgetTester tester, {
    double value = 0.1,
    List<double> marks = const [],
    Color? activeColor,
    Object? Function(double value)? detentOf,
  }) async {
    values = [];
    haptics = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    var current = value;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) => GlassSlider(
                  value: current,
                  marks: marks,
                  activeColor: activeColor,
                  detentOf: detentOf,
                  onChanged: (next) {
                    values.add(next);
                    setState(() => current = next);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The tallest rounded box the slider paints: the thumb. The groove is
  /// [GlassSlider.trackHeight] tall.
  Size thumb(WidgetTester tester) {
    var size = Size.zero;
    expect(
      tester.renderObject(find.byType(Slider)),
      paints..everything((method, arguments) {
        if (method == #drawRRect) {
          final box = arguments.first as RRect;
          if (box.height > size.height) size = Size(box.width, box.height);
        }
        return true;
      }),
    );
    return size;
  }

  /// The x of [value] on the slider.
  double x(WidgetTester tester, double value) {
    final slider = tester.getRect(find.byType(Slider));
    return slider.left +
        GlassSlider.thumbSize.width / 2 +
        value * (slider.width - GlassSlider.thumbSize.width);
  }

  testWidgets('a drag taps once as it reaches or crosses each mark, '
      'without a snap', (tester) async {
    await pump(tester, marks: const [0.3, 0.5, 0.7]);
    final y = tester.getCenter(find.byType(Slider)).dy;

    final gesture = await tester.startGesture(Offset(x(tester, 0.1), y));
    for (var i = 1; i <= 16; i++) {
      await gesture.moveTo(Offset(x(tester, 0.1 + i * 0.05), y));
      await tester.pump();
    }
    expect(haptics, List.filled(3, 'HapticFeedbackType.lightImpact'));

    // The values pass the marks by, between and on them.
    expect(values.where((value) => value > 0.3 && value < 0.5), isNotEmpty);

    // Back over 0.7 and 0.5, to 0.375.
    for (var i = 1; i <= 7; i++) {
      await gesture.moveTo(Offset(x(tester, 0.9 - i * 0.075), y));
      await tester.pump();
    }
    expect(haptics, hasLength(5));
    await gesture.up();
  });

  testWidgets('with detents, a drag clicks on each new detent, taps harder '
      'on a mark, and knocks at the ends, once per move', (tester) async {
    await pump(
      tester,
      marks: const [0.5],
      detentOf: (value) => (value * 10).floor(),
    );
    final y = tester.getCenter(find.byType(Slider)).dy;
    const click = 'HapticFeedbackType.selectionClick';
    const tap = 'HapticFeedbackType.lightImpact';
    const knock = 'HapticFeedbackType.mediumImpact';

    // From the detent of 0.1, through one detent per move.
    final gesture = await tester.startGesture(Offset(x(tester, 0.15), y));
    await tester.pump();
    expect(haptics, isEmpty);
    for (final value in [0.25, 0.35, 0.45, 0.55, 0.65]) {
      await gesture.moveTo(Offset(x(tester, value), y));
      await tester.pump();
    }
    expect(haptics, [click, click, click, tap, click]);

    // A move within one detent is quiet.
    await gesture.moveTo(Offset(x(tester, 0.66), y));
    await tester.pump();
    expect(haptics, hasLength(5));

    // Past the end, then back past the start, over the mark.
    await gesture.moveTo(Offset(x(tester, 1) + 40, y));
    await tester.pump();
    await gesture.moveTo(Offset(x(tester, 0) - 40, y));
    await tester.pump();
    expect(haptics.skip(5), [knock, knock]);
    await gesture.up();
  });

  testWidgets('the thumb grows while the finger holds it, and settles back '
      'on release', (tester) async {
    await pump(tester, value: 0.5);
    final rest = thumb(tester);
    expect(rest, GlassSlider.thumbSize);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    final held = thumb(tester);
    expect(held.width, greaterThan(rest.width * 1.3));
    expect(held.height, greaterThan(rest.height * 1.15));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(thumb(tester), rest);
  });

  testWidgets('the track is a groove of the glass, filled with the primary '
      'text color or the given color, with no overlay halo', (tester) async {
    await pump(tester);
    final context = tester.element(find.byType(Slider));
    SliderThemeData theme() =>
        SliderTheme.of(tester.element(find.byType(Slider)));

    expect(theme().inactiveTrackColor, GlassStyle.of(context).groove);
    expect(theme().activeTrackColor, context.colors.textPrimary);
    expect(theme().overlayShape, SliderComponentShape.noOverlay);
    expect(theme().trackHeight, GlassSlider.trackHeight);

    await pump(tester, activeColor: Colors.orange);
    expect(theme().activeTrackColor, Colors.orange);
  });

  testWidgets('it is a 48 pt touch row', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(Slider)).height, 48);
  });
}
