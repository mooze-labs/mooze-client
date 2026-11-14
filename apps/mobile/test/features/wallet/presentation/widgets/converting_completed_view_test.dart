import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/conversion_scene.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/converting_completed_view.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  late List<String> haptics;

  setUp(() => haptics = []);

  /// [home] in the app, with [reduceMotion] as the system setting, at
  /// '/', next to a '/home' route.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(path: '/home', builder: (_, _) => const Text('home')),
          ],
        ),
      ),
    );
  }

  double scene(WidgetTester tester) => tester
      .widget<ConversionScene>(
        find.byType(ConversionScene, skipOffstage: false),
      )
      .animation
      .value;

  double opacityAbove(WidgetTester tester, Finder finder) => tester
      .widget<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)).first,
      )
      .opacity
      .value;

  const peg = ConvertingCompletedView(
    fromAsset: Asset.btc,
    toAsset: Asset.lbtc,
  );

  testWidgets('the coins of the peg play first; the existing title and '
      'message wait for the landing, the button comes last', (tester) async {
    await pump(tester, peg);

    final view = tester.widget<ConversionScene>(find.byType(ConversionScene));
    expect(view.fromAsset, Asset.btc);
    expect(view.toAsset, Asset.lbtc);

    final title = find.text(t.converting_details_completed_title);
    final button = find.text(t.converting_details_back_to_home);
    expect(find.text(t.converting_details_completed_message), findsOneWidget);

    // Just before the landing, nothing reads yet.
    await tester.pump(
      Motion.durationConversion * (ConversionScene.landAt - 0.02),
    );
    expect(opacityAbove(tester, title), 0);
    expect(opacityAbove(tester, button), 0);

    await tester.pump(Motion.durationConversion);
    expect(opacityAbove(tester, title), 1);
    expect(opacityAbove(tester, button), 1);
    // At rest, nothing moves any more.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('under reduced motion everything shows at once, with one '
      'light haptic', (tester) async {
    await pump(tester, peg, reduceMotion: true);

    expect(scene(tester), 1);
    expect(
      opacityAbove(tester, find.text(t.converting_details_completed_title)),
      1,
    );
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  // The confirmation of the received credit often opens over the details
  // just before the peg leaves the list. A scene that played behind it
  // would be lost.
  testWidgets('under another screen the scene waits, and plays once the '
      'view is on top', (tester) async {
    var shown = false;
    late StateSetter show;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          show = setState;
          return shown ? peg : const SizedBox();
        },
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const Text('received')),
    );
    await tester.pumpAndSettle();

    show(() => shown = true);
    await tester.pump();
    await tester.pump(Motion.durationConversion);
    expect(scene(tester), 0);
    expect(haptics, isEmpty);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(scene(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(scene(tester), 1);
    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  testWidgets('pushed on its own, the scene starts once its route is in '
      'place', (tester) async {
    await pump(tester, const Text('start'));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => peg));
    await tester.pump();
    // The page transition runs for 300 ms.
    await tester.pump(const Duration(milliseconds: 200));
    expect(scene(tester), 0);

    await tester.pumpAndSettle();
    expect(scene(tester), 1);
  });

  testWidgets('the button goes home', (tester) async {
    await pump(tester, peg);
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.converting_details_back_to_home));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('given onDone, the button does that instead', (tester) async {
    var done = 0;
    await pump(
      tester,
      ConvertingCompletedView(
        fromAsset: Asset.lbtc,
        toAsset: Asset.btc,
        onDone: () => done++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.converting_details_back_to_home));
    await tester.pumpAndSettle();
    expect(done, 1);
    expect(find.text('home'), findsNothing);
  });
}
