import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_lifecycle_controller.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/wallet_deleting/wallet_deleting_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/wallet_deleting/widgets/closing_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/widgets/onboarding_scene.dart';
import 'package:mooze_mobile/features/setup/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../shared/widgets/motion/motion_test_helpers.dart';
import '../../../setup/presentation/setup_test_app.dart';

/// A lifecycle controller whose deletes the test settles by hand.
class _FakeLifecycle implements AppLifecycleController {
  /// One completer per call to [deleteWalletAndReimport].
  final deletes = <Completer<Either<Failure, Unit>>>[];

  @override
  Future<Either<Failure, Unit>> deleteWalletAndReimport() {
    final delete = Completer<Either<Failure, Unit>>();
    deletes.add(delete);
    return delete.future;
  }

  @override
  Stream<AppState> get state => const Stream.empty();

  @override
  AppState get currentState => const AppState(phase: AppPhase.ready);

  @override
  Future<Either<Failure, AppState>> start() => throw UnimplementedError();

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> dispose() async {}
}

class _MockSession extends Mock implements SessionManagerService {}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);
  const deleting = '/settings/delete-wallet/deleting';
  const medium = 'HapticFeedbackType.mediumImpact';
  const light = 'HapticFeedbackType.lightImpact';

  late _FakeLifecycle lifecycle;
  late _MockSession session;
  late OpenedRoutes opened;
  late List<(String, Duration)> haptics;
  late Duration clock;
  Duration? forgotAt;

  setUp(() {
    lifecycle = _FakeLifecycle();
    session = _MockSession();
    forgotAt = null;
    when(() => session.resetIdentity()).thenAnswer((_) {
      forgotAt = clock;
      return TaskEither.right(unit);
    });
    opened = OpenedRoutes();
    haptics = [];
    clock = Duration.zero;
  });

  Future<void> advance(WidgetTester tester, Duration time) async {
    final end = clock + time;
    while (clock < end) {
      await tester.pump(step);
      clock += step;
    }
  }

  /// Opens the deleting screen over another one, as it opens over the
  /// delete screen, and waits for its page transition.
  /// With [realOnboarding], the onboarding is the one of the app, not a
  /// stub.
  Future<void> open(WidgetTester tester, {bool realOnboarding = false}) async {
    usePhoneSize(tester);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add((call.arguments as String, clock));
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final router = GoRouter(
      initialLocation: '/before',
      routes: [
        GoRoute(
          path: '/before',
          builder: (_, _) => const Scaffold(body: Text('before')),
        ),
        GoRoute(
          path: deleting,
          builder: (_, _) => const WalletDeletingScreen(),
        ),
        if (realOnboarding)
          setupRoutes.whereType<GoRoute>().singleWhere(
            (route) => route.path == '/setup/onboarding',
          )
        else
          opened.stub('/setup/onboarding'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        overrides: [
          appLifecycleControllerProvider.overrideWith((_) async => lifecycle),
          sessionManagerServiceProvider.overrideWithValue(session),
        ],
      ),
    );
    unawaited(router.push(deleting));
    await tester.pump();
    await tester.pump();
  }

  ClosingMotion motion(WidgetTester tester) =>
      tester.widget<ClosingScene>(find.byType(ClosingScene)).motion;

  double departure(WidgetTester tester, Asset asset) =>
      motion(tester).departures[asset] ?? 0;

  /// Whether the caption of [title] is the one on show. The other caption
  /// stays in the tree to size the region, but offstage.
  bool shows(WidgetTester tester, String title) =>
      find.text(title).evaluate().isNotEmpty;

  /// Pumps frames until the onboarding opens. Returns when the farewell
  /// started and ended, when the caption told that the wallet is deleted,
  /// when the onboarding opened, and whether the farewell ever played while
  /// a coin was still on the orbit.
  Future<
    ({
      Duration farewellStart,
      Duration farewellEnd,
      Duration doneShown,
      Duration onboarding,
      bool farewellBeforeLeaving,
      bool restedAfterFarewell,
    })
  >
  untilOnboarding(WidgetTester tester) async {
    Duration? farewellStart, farewellEnd, doneShown;
    var farewellBeforeLeaving = false;
    bool? restedAfterFarewell;
    while (opened.last == null && clock < const Duration(seconds: 20)) {
      if (find.byType(ClosingScene).evaluate().isNotEmpty) {
        final m = motion(tester);
        if (m.farewell > 0) {
          farewellStart ??= clock;
          if (Asset.values.any((asset) => (m.departures[asset] ?? 0) < 1)) {
            farewellBeforeLeaving = true;
          }
        }
        if (m.farewell == 1 && farewellEnd == null) {
          farewellEnd = clock;
          // One frame for the controller to complete, then nothing moves.
          await tester.pump(step);
          clock += step;
          restedAfterFarewell = !tester.binding.hasScheduledFrame;
          continue;
        }
        if (doneShown == null && shows(tester, t.wallet_delete_step_done)) {
          doneShown = clock;
        }
      }
      await tester.pump(step);
      clock += step;
    }
    expect(opened.last, '/setup/onboarding');
    return (
      farewellStart: farewellStart!,
      farewellEnd: farewellEnd!,
      doneShown: doneShown!,
      onboarding: clock,
      farewellBeforeLeaving: farewellBeforeLeaving,
      restedAfterFarewell: restedAfterFarewell!,
    );
  }

  group('ClosingScene', () {
    test('the Mooze coin is edge-on at the peak, wherever its sway stopped, '
        'and turns only forward', () {
      for (var spin = 0.0; spin <= 1; spin += 0.01) {
        double turn(double farewell) => ClosingScene.coreAt(
          ClosingMotion(spin: spin, farewell: farewell),
        ).turn;

        expect(turn(ClosingScene.edgeOnAt), math.pi / 2, reason: '$spin');
        expect(turn(ClosingScene.edgeOnAt - 0.01), lessThan(math.pi / 2));
        expect(turn(ClosingScene.edgeOnAt + 0.01), greaterThan(math.pi / 2));
        var last = turn(0);
        for (var f = 0.0; f <= 1; f += 0.01) {
          expect(turn(f), greaterThanOrEqualTo(last - 1e-9));
          last = turn(f);
        }
        // It rests on its face, turned slightly, the same at every stop.
        expect(StageToken.faceYaw(turn(1)), closeTo(0.3, 1e-9));
      }
    });

    test('the coin has sunk to rest when the light haptic plays', () {
      double sink(double farewell) =>
          ClosingScene.coreAt(ClosingMotion(farewell: farewell)).sink;
      expect(sink(0.3), 0);
      expect(sink(ClosingScene.landAt - 0.05), lessThan(1));
      expect(sink(ClosingScene.landAt), 1);
    });
  });

  testWidgets('the coins wait for the page transition, then leave the orbit '
      'one after another, the last one in first', (tester) async {
    await open(tester);
    expect(lifecycle.deletes, hasLength(1));
    for (final asset in Asset.values) {
      expect(departure(tester, asset), 0, reason: asset.name);
    }

    // Under the page transition, every coin waits.
    await advance(tester, const Duration(milliseconds: 200));
    for (final asset in Asset.values) {
      expect(departure(tester, asset), 0, reason: asset.name);
    }

    // Then the first stagger step.
    await advance(tester, const Duration(milliseconds: 400));
    expect(departure(tester, Asset.usdt), greaterThan(0));
    expect(departure(tester, Asset.btc), 0);
    final usdt = departure(tester, Asset.usdt);
    final depix = departure(tester, Asset.depix);
    final lbtc = departure(tester, Asset.lbtc);
    expect(usdt, greaterThan(depix));
    expect(depix, greaterThanOrEqualTo(lbtc));

    await advance(tester, const Duration(seconds: 2));
    for (final asset in Asset.values) {
      expect(departure(tester, asset), 1, reason: asset.name);
    }
    // The wallet is not deleted yet: the caption still says so.
    expect(shows(tester, t.wallet_delete_step_deleting), isTrue);
    expect(shows(tester, t.wallet_delete_step_done), isFalse);
    expect(motion(tester).farewell, 0);
    expect(opened.last, isNull);
  });

  testWidgets('once the wallet is deleted, the farewell plays with two '
      'haptics, the caption says so, and the app starts over at the '
      'onboarding', (tester) async {
    await open(tester);
    await advance(tester, const Duration(seconds: 3));
    lifecycle.deletes.single.complete(const Right(unit));

    final run = await untilOnboarding(tester);
    final farewell = Motion.durationFarewell;

    expect(run.farewellBeforeLeaving, isFalse);
    expect(run.restedAfterFarewell, isTrue);
    expect([for (final (type, _) in haptics) type], [medium, light]);
    final (_, peak) = haptics[0];
    final (_, land) = haptics[1];
    // Each haptic on its beat, within two frames.
    expect(
      (peak - run.farewellStart - farewell * ClosingScene.edgeOnAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    expect(
      (land - run.farewellStart - farewell * ClosingScene.landAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    // The caption waits for the peak.
    expect(
      run.doneShown - run.farewellStart,
      greaterThanOrEqualTo(farewell * ClosingScene.revealAt - step * 2),
    );
    // "Wallet deleted" stays for a beat once the scene rests, and the app
    // forgets the wallet only right before the onboarding opens.
    expect(
      run.onboarding - run.farewellEnd,
      greaterThanOrEqualTo(WalletDeletingScreen.doneHold),
    );
    expect(forgotAt, greaterThanOrEqualTo(run.farewellEnd));
    verify(() => session.resetIdentity()).called(1);
    expect(lifecycle.deletes, hasLength(1));
    // The onboarding takes the Mooze coin as it is.
    expect(opened.extras.last, OnboardingEntrance.coinInPlace);
  });

  testWidgets('the Mooze coin flies on into the onboarding as one coin, and '
      'the asset coins of a new wallet come out of it once it has landed', (
    tester,
  ) async {
    await open(tester, realOnboarding: true);
    lifecycle.deletes.single.complete(const Right(unit));
    final mooze = find.byWidgetPredicate(
      (widget) =>
          widget is GlyphToken &&
          widget.glyphPath == 'assets/images/onboarding/mooze_m.svg',
    );
    final onboarding = find.byType(OnboardingSceneView);

    // Until the onboarding opens, the coin rests on the deleting screen.
    while (onboarding.evaluate().isEmpty) {
      expect(clock, lessThan(const Duration(seconds: 15)));
      await advance(tester, step);
    }
    final from = tester.getCenter(mooze);
    expect(find.byType(ClosingScene), findsOneWidget);
    // The caption has left: only the coin is on the stage.
    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('captions')))
          .opacity,
      0,
    );

    // One coin all the way, rising from its place to the onboarding's,
    // while the onboarding waits for it.
    final heights = <double>[from.dy];
    while (find.byType(ClosingScene).evaluate().isNotEmpty) {
      expect(mooze, findsOneWidget);
      heights.add(tester.getCenter(mooze).dy);
      expect(tester.widget<OnboardingSceneView>(onboarding).motion.time, 0);
      await advance(tester, step);
    }
    expect(mooze, findsOneWidget);
    final to = tester.getCenter(mooze);
    expect(to.dy, lessThan(from.dy));
    for (var i = 1; i < heights.length; i++) {
      expect(heights[i], lessThanOrEqualTo(heights[i - 1] + 0.01));
    }
    expect(heights.where((dy) => dy < from.dy && dy > to.dy), isNotEmpty);

    // Landed: the coin keeps its place and size, and the scene starts.
    final landed = tester.getRect(mooze);
    final motion = tester.widget<OnboardingSceneView>(onboarding).motion;
    expect(motion.coinInPlace, isTrue);
    await advance(tester, const Duration(milliseconds: 300));
    expect(
      tester.widget<OnboardingSceneView>(onboarding).motion.time,
      greaterThan(0),
    );
    expect(tester.getRect(mooze).center.dx, landed.center.dx);
    expect(tester.getRect(mooze).width, moreOrLessEquals(landed.width));
  });

  testWidgets('a fast delete still plays the whole scene: every coin leaves '
      'before the farewell', (tester) async {
    await open(tester);
    lifecycle.deletes.single.complete(const Right(unit));

    final run = await untilOnboarding(tester);
    expect(run.farewellBeforeLeaving, isFalse);
    // Three stagger steps and a departure, before the farewell starts.
    expect(
      run.farewellStart,
      greaterThanOrEqualTo(
        WalletDeletingScreen.departureStagger * 3 + Motion.durationSlow * 2,
      ),
    );
  });

  testWidgets('the scene does not move when the caption changes', (
    tester,
  ) async {
    await open(tester);
    // Measured once the page transition is over.
    await advance(tester, const Duration(milliseconds: 600));
    final before = tester.getRect(find.byType(ClosingScene));
    lifecycle.deletes.single.complete(const Right(unit));
    while (!shows(tester, t.wallet_delete_step_done)) {
      expect(clock, lessThan(const Duration(seconds: 6)));
      await advance(tester, step);
    }
    expect(tester.getRect(find.byType(ClosingScene)), before);
  });

  testWidgets('the screen cannot be left while the wallet is deleted', (
    tester,
  ) async {
    await open(tester);
    await advance(tester, const Duration(milliseconds: 600));

    await tester.binding.handlePopRoute();
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.byType(ClosingScene), findsOneWidget);
    expect(find.text('before'), findsNothing);
  });

  testWidgets('a failed delete brings the coins back to the orbit and '
      'offers to try again, which deletes again', (tester) async {
    await open(tester);
    await advance(tester, const Duration(milliseconds: 900));
    lifecycle.deletes.single.complete(
      const Left(CredentialFailure('credential delete failed')),
    );
    await advance(tester, const Duration(seconds: 2));

    expect(find.text(t.wallet_delete_error_title), findsOneWidget);
    for (final asset in Asset.values) {
      expect(departure(tester, asset), 0, reason: asset.name);
    }
    expect(motion(tester).farewell, 0);
    expect(haptics, isEmpty);
    expect(opened.last, isNull);

    await tester.tap(find.text(t.common_retry));
    await advance(tester, const Duration(milliseconds: 400));
    expect(lifecycle.deletes, hasLength(2));
    expect(find.text(t.wallet_delete_error_title), findsNothing);
    expect(departure(tester, Asset.usdt), greaterThan(0));

    lifecycle.deletes.last.complete(const Right(unit));
    await untilOnboarding(tester);
  });

  testWidgets('a delete that throws fails the same way, and the user can go '
      'back', (tester) async {
    await open(tester);
    await advance(tester, const Duration(milliseconds: 600));
    lifecycle.deletes.single.completeError(StateError('disk gone'));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text(t.wallet_delete_error_title), findsOneWidget);

    await tester.tap(find.text(t.common_back));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.byType(ClosingScene), findsNothing);
    expect(find.text('before'), findsOneWidget);
    verifyNever(() => session.resetIdentity());
  });

  testWidgets('with reduced motion, nothing moves: the scene shows its end '
      'at once, with one light haptic', (tester) async {
    reduceMotion(tester);
    await open(tester);
    // The page transition of the test router is not the scene's.
    await advance(tester, const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isFalse);
    for (final asset in Asset.values) {
      expect(departure(tester, asset), 1, reason: asset.name);
    }

    lifecycle.deletes.single.complete(const Right(unit));
    await tester.pump();
    await tester.pump();
    expect(motion(tester).farewell, 1);
    expect(shows(tester, t.wallet_delete_step_done), isTrue);
    expect([for (final (type, _) in haptics) type], [light]);

    await advance(tester, WalletDeletingScreen.doneHold + step * 2);
    expect(opened.last, '/setup/onboarding');
  });
}
