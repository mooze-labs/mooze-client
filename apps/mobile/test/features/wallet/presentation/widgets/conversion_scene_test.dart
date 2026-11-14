import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/conversion_scene.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// The scene of a peg-in, BTC to L-BTC, can be read at any point of its
/// timeline: which coin is in front, and the haptics on its beats.
void main() {
  /// The haptics played, each with the progress of the scene at the time.
  late List<(String, double)> haptics;

  /// The scene driven by a controller that starts at [startAt].
  Future<AnimationController> pump(
    WidgetTester tester, {
    double startAt = 0,
    bool light = false,
  }) async {
    final controller = AnimationController(
      vsync: tester,
      duration: Motion.durationConversion,
      value: startAt,
    );
    addTearDown(controller.dispose);
    haptics = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add((call.arguments as String, controller.value));
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Theme(
          data: light
              ? AppTheme.lightTheme(context)
              : AppTheme.darkTheme(context),
          child: child!,
        ),
        home: Scaffold(
          body: ConversionScene(
            fromAsset: Asset.btc,
            toAsset: Asset.lbtc,
            animation: controller,
          ),
        ),
      ),
    );
    return controller;
  }

  StagePlaced coin(WidgetTester tester, String role) =>
      tester.widget<StagePlaced>(find.byKey(ValueKey(role)));

  /// The coins from the back to the front of the stage.
  List<String> depth(WidgetTester tester) {
    final stack = find
        .ancestor(
          of: find.byKey(const ValueKey('from')),
          matching: find.byType(Stack),
        )
        .first;
    return [
      for (final child in tester.widget<Stack>(stack).children)
        if (child.key case ValueKey<String>(:final value)) value,
    ];
  }

  testWidgets('the sent coin starts in front, and the received coin lands '
      'in front of it', (tester) async {
    final controller = await pump(tester);

    controller.value = 0.1;
    await tester.pump();
    expect(depth(tester), ['to', 'from']);
    expect(coin(tester, 'from').scale, greaterThan(coin(tester, 'to').scale));

    controller.value = 1;
    await tester.pump();
    expect(depth(tester), ['from', 'to']);
    expect(coin(tester, 'to').scale, greaterThan(coin(tester, 'from').scale));
    // The sent coin rests behind, dimmed, so the received one leads.
    expect(coin(tester, 'to').opacity, greaterThan(0.9));
    expect(coin(tester, 'from').opacity, lessThan(0.6));
  });

  // The peak is one frame: the coin arrives with the flash and the heavy
  // impact, then only swells in place.
  testWidgets('the received coin is in its place as it lands', (tester) async {
    final controller = await pump(tester);

    controller.value = ConversionScene.landAt;
    await tester.pump();
    final landed = coin(tester, 'to').at;
    controller.value = 1;
    await tester.pump();
    expect(coin(tester, 'to').at, landed);

    controller.value = ConversionScene.landAt - 0.1;
    await tester.pump();
    expect(coin(tester, 'to').at, isNot(landed));
  });

  // A flash draws even at its start. Unguarded, a pink disc would follow
  // the received coin across the stage before it lands.
  testWidgets('the flash waits for the landing', (tester) async {
    final controller = await pump(tester);
    final back = find
        .descendant(
          of: find.byType(ConversionScene),
          matching: find.byType(CustomPaint),
        )
        .first;
    // The flash starts at 0.3 of the radius of a coin, among the other
    // circles of the stage.
    final flash = paints
      ..something(
        (method, arguments) =>
            method == #drawCircle &&
            arguments[1] == ConversionScene.coinSize / 2 * 0.3,
      );

    controller.value = ConversionScene.landAt - 0.05;
    await tester.pump();
    expect(back, isNot(flash));

    controller.value = ConversionScene.landAt;
    await tester.pump();
    expect(back, flash);
  });

  testWidgets('a light impact as the coins set off, a heavy one as the '
      'received coin lands', (tester) async {
    final controller = await pump(tester);

    controller.forward();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(haptics.map((h) => h.$1), [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
    expect(haptics.first.$2, lessThan(0.02));
    // On the first frame at or past the landing.
    expect(
      haptics.last.$2,
      inInclusiveRange(ConversionScene.landAt, ConversionScene.landAt + 0.01),
    );
  });

  testWidgets('a scene shown at rest plays no haptic', (tester) async {
    await pump(tester, startAt: 1);
    await tester.pump(const Duration(milliseconds: 16));

    expect(haptics, isEmpty);
  });

  for (final light in [false, true]) {
    testWidgets('every moment draws in the ${light ? 'light' : 'dark'} '
        'theme', (tester) async {
      final controller = await pump(tester, light: light);

      for (final t in [0.0, 0.2, 0.42, 0.66, 0.7, 0.85, 1.0]) {
        controller.value = t;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'at $t');
      }
    });
  }
}
