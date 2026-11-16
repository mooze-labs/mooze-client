import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_lifecycle_controller.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/app/session/privacy_shield_controller.dart';
import 'package:mooze_mobile/app/session/privacy_shield_state.dart';
import 'package:mooze_mobile/app/session/session_lock_controller.dart';
import 'package:mooze_mobile/app/session/session_lock_state.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/boot/domain/boot_state.dart';
import 'package:mooze_mobile/features/setup/di/providers/pin_setup_repository_provider.dart';
import 'package:mooze_mobile/features/setup/domain/repositories/pin_setup_repository.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/confirm_pin_setup.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/wallet_import_loading/widgets/opening_scene.dart';
import 'package:mooze_mobile/features/setup/routes.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_hero.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

/// Biometrics whose prompts the test settles by hand.
class _FakeBiometrics implements BiometricService {
  _FakeBiometrics(this.enrolled);

  BiometricCapabilities enrolled;

  /// One completer per prompt.
  final prompts = <Completer<Either<AuthError, bool>>>[];
  final saved = <bool>[];
  bool saveFails = false;

  @override
  TaskEither<AuthError, bool> unlockWithBiometric({required String reason}) {
    final prompt = Completer<Either<AuthError, bool>>();
    prompts.add(prompt);
    return TaskEither(() => prompt.future);
  }

  @override
  TaskEither<String, Unit> setEnabled(bool enabled) => TaskEither(() async {
    if (saveFails) return const Left('disk full');
    saved.add(enabled);
    return const Right(unit);
  });

  @override
  Task<BiometricCapabilities> capabilities() => Task.of(enrolled);

  @override
  Task<bool> isAvailable() => Task.of(enrolled.hasAnyAuth);

  @override
  Task<bool> isEnabled() => Task.of(saved.lastOrNull ?? false);

  @override
  TaskEither<AuthError, bool> unlockWithDeviceCredential({
    required String reason,
    String? title,
    String? subtitle,
  }) => throw UnimplementedError();
}

/// A lifecycle controller that opens the wallet when the test says so.
class _FakeLifecycle implements AppLifecycleController {
  final starts = <Completer<Either<Failure, AppState>>>[];

  @override
  Stream<AppState> get state => const Stream.empty();

  @override
  AppState get currentState => const AppState(phase: AppPhase.uninitialized);

  @override
  Future<Either<Failure, AppState>> start() {
    final start = Completer<Either<Failure, AppState>>();
    starts.add(start);
    return start.future;
  }

  @override
  Future<void> shutdown() async {}

  @override
  Future<Either<Failure, Unit>> deleteWalletAndReimport() =>
      throw UnimplementedError();

  @override
  Future<void> dispose() async {}
}

class _FakePins implements PinSetupRepository {
  @override
  TaskEither<String, Unit> createPin(String pin) => TaskEither.right(unit);

  @override
  TaskEither<String, bool> validatePin(String pin) => TaskEither.right(true);
}

const _faceId = BiometricCapabilities(
  hasBiometrics: true,
  hasAnyAuth: true,
  hasFaceId: true,
  hasFingerprint: false,
);
const _fingerprint = BiometricCapabilities(
  hasBiometrics: true,
  hasAnyAuth: true,
  hasFaceId: false,
  hasFingerprint: true,
);
const _passcodeOnly = BiometricCapabilities(
  hasBiometrics: false,
  hasAnyAuth: true,
  hasFaceId: false,
  hasFingerprint: false,
);

GoRoute _route(String path) =>
    setupRoutes.whereType<GoRoute>().singleWhere((route) => route.path == path);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);
  const medium = 'HapticFeedbackType.mediumImpact';
  const light = 'HapticFeedbackType.lightImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';

  late _FakeBiometrics biometrics;
  late OpenedRoutes opened;
  late List<(String, Duration)> haptics;
  late Duration clock;

  setUp(() {
    biometrics = _FakeBiometrics(_fingerprint);
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

  void recordHaptics(WidgetTester tester) {
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
  }

  /// Opens the biometric screen of the app over another screen, as the
  /// confirmation of the PIN does, with [capabilities] as its extra.
  Future<void> open(
    WidgetTester tester, {
    BiometricCapabilities? capabilities = _fingerprint,
    List<Override> overrides = const [],
  }) async {
    usePhoneSize(tester);
    recordHaptics(tester);
    final router = GoRouter(
      initialLocation: '/before',
      routes: [
        GoRoute(path: '/before', builder: (_, _) => const Scaffold()),
        _route('/setup/biometric'),
        opened.stub('/setup/wallet-import-loading'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        overrides: [
          biometricServiceProvider.overrideWithValue(biometrics),
          ...overrides,
        ],
      ),
    );
    router.go('/setup/biometric', extra: capabilities);
    await tester.pump();
    await tester.pump();
    // The page transition.
    await advance(tester, const Duration(milliseconds: 600));
  }

  BiometricScene scene(WidgetTester tester) =>
      tester.widget<BiometricScene>(find.byType(BiometricScene));

  Finder button(String method) => find.text(t.biometric_setup_button(method));

  /// The state of the scene, kept as numbers for a quick look.
  ({double scan, double success, double shake}) motion(WidgetTester tester) {
    final m = scene(tester).motion;
    return (scan: m.scan, success: m.success, shake: m.shake);
  }

  bool shows(String text) => find.text(text).evaluate().isNotEmpty;

  /// The opacity the message of a problem is going to.
  double messageOpacity(WidgetTester tester, String message) => tester
      .widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text(message, skipOffstage: false),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      )
      .opacity;

  group('BiometricKind', () {
    test('an iPhone shows what it has: a face or a fingerprint', () {
      expect(BiometricKind.of(_faceId), BiometricKind.face);
      expect(BiometricKind.of(_fingerprint), BiometricKind.fingerprint);
    });

    test('Android, which mostly reports only a strength, shows a '
        'fingerprint, even with a face too', () {
      expect(
        BiometricKind.of(
          const BiometricCapabilities(
            hasBiometrics: true,
            hasAnyAuth: true,
            hasFaceId: true,
            hasFingerprint: true,
          ),
        ),
        BiometricKind.fingerprint,
      );
    });
  });

  group('BiometricScene', () {
    test('the seal is edge-on when it becomes the Mooze coin, wherever its '
        'sway stopped, and rests at the yaw of the opening', () {
      for (var ambient = 0.0; ambient <= 1; ambient += 0.05) {
        BiometricMotion at(double success) =>
            BiometricMotion(ambient: ambient, success: success);
        final edge = BiometricScene.sealAt(at(BiometricScene.edgeOnAt));
        expect(edge.turn, math.pi / 2);
        expect(edge.showsCoin, isTrue);
        // No jump: the turn comes to edge-on smoothly.
        expect(
          BiometricScene.sealAt(at(BiometricScene.edgeOnAt - 0.001)).turn,
          closeTo(math.pi / 2, 0.03),
        );
        final before = BiometricScene.sealAt(
          at(BiometricScene.edgeOnAt - 0.01),
        );
        expect(before.turn, lessThan(math.pi / 2));
        expect(before.showsCoin, isFalse);
        for (final success in [BiometricScene.restAt, 1.0]) {
          expect(
            StageToken.faceYaw(BiometricScene.sealAt(at(success)).turn),
            closeTo(BiometricScene.restYaw, 1e-9),
          );
        }
      }
      // The Mooze coin of the opening starts at the same yaw.
      expect(BiometricScene.restYaw, 0.3);
    });

    test('a shake ends where it started', () {
      expect(
        BiometricScene.sealAt(const BiometricMotion(shake: 0.3)).dx,
        isNot(0),
      );
      expect(BiometricScene.sealAt(const BiometricMotion(shake: 1)).dx, 0);
    });
  });

  group('in the words of the device', () {
    testWidgets(
      'an iPhone with Face ID says Face ID, and its seal shows a face',
      (tester) async {
        await open(tester, capabilities: _faceId);
        expect(
          shows(t.biometric_setup_title(t.biometric_method_face_id)),
          isTrue,
        );
        expect(button(t.biometric_method_face_id), findsOneWidget);
        expect(scene(tester).kind, BiometricKind.face);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'an iPhone with Touch ID says Touch ID',
      (tester) async {
        await open(tester);
        expect(button(t.biometric_method_touch_id), findsOneWidget);
        expect(scene(tester).kind, BiometricKind.fingerprint);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'Android says biometrics, with a fingerprint',
      (tester) async {
        await open(tester);
        expect(button(t.biometric_method_generic), findsOneWidget);
        expect(scene(tester).kind, BiometricKind.fingerprint);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'without them from the route, the screen reads them',
      (tester) async {
        biometrics.enrolled = _faceId;
        await open(tester, capabilities: null);
        expect(button(t.biometric_method_face_id), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  testWidgets('the seal enters after the page, sways, and rests within 5 s', (
    tester,
  ) async {
    await open(tester);
    await advance(tester, const Duration(seconds: 5));
    await tester.pump(step);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('while the system prompt is up, the seal scans, and nothing '
      'else can start', (tester) async {
    await open(tester);
    final method = t.biometric_method_generic;
    await tester.tap(button(method));
    await advance(tester, const Duration(milliseconds: 400));
    expect(motion(tester).scan, 1);
    final sweep = scene(tester).motion.sweep;
    await advance(tester, const Duration(milliseconds: 200));
    expect(scene(tester).motion.sweep, isNot(sweep));

    await tester.tap(button(method));
    await tester.tap(find.text(t.common_no_thanks));
    await advance(tester, const Duration(milliseconds: 100));
    expect(biometrics.prompts, hasLength(1));
    expect(opened.last, isNull);
  });

  testWidgets('a dismissed prompt leaves the screen as it was', (tester) async {
    await open(tester);
    await tester.tap(button(t.biometric_method_generic));
    await advance(tester, const Duration(milliseconds: 400));
    biometrics.prompts.single.complete(const Right(false));
    await advance(tester, const Duration(milliseconds: 400));

    expect(motion(tester).scan, 0);
    expect(opened.last, isNull);
    expect(biometrics.saved, isEmpty);
    expect(haptics, isEmpty);
    expect(messageOpacity(tester, t.biometric_setup_failed), 0);
    // It can try again.
    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    expect(biometrics.prompts, hasLength(2));
  });

  testWidgets('the system prompt is no backgrounding: the privacy shield '
      'stays down and the app does not lock when it closes', (tester) async {
    // The defaults: shield and lock on, lock at once.
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await open(
      tester,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    final providers = ProviderScope.containerOf(
      tester.element(find.byType(BiometricScene)),
    );
    final shield = providers.read(privacyShieldControllerProvider.notifier);
    final lock = providers.read(sessionLockControllerProvider.notifier);
    // What the app hears as it leaves the foreground, as the lifecycle
    // observer passes it on: `inactive` on iOS, `paused` on Android.
    void leaves() {
      shield.onInactive();
      shield.onLeavingForeground();
      lock.onBackgrounded();
    }

    void returns() {
      lock.onResumed();
      shield.onResumed();
    }

    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    leaves();
    expect(
      providers.read(privacyShieldControllerProvider),
      PrivacyShieldState.hidden,
    );
    biometrics.prompts.single.complete(const Right(false));
    await tester.pump();
    returns();
    expect(
      providers.read(sessionLockControllerProvider),
      SessionLockState.unlocked,
    );

    // Once the prompt is closed, leaving the app still covers and locks it.
    leaves();
    expect(
      providers.read(privacyShieldControllerProvider),
      PrivacyShieldState.visible,
    );
    returns();
    expect(
      providers.read(sessionLockControllerProvider),
      SessionLockState.locked,
    );
  });

  testWidgets('a lockout shakes the seal and tells why, and the button '
      'tries again', (tester) async {
    await open(tester);
    await tester.tap(button(t.biometric_method_generic));
    await advance(tester, const Duration(milliseconds: 300));
    biometrics.prompts.single.complete(
      const Left(AuthError(code: 'LockedOut', message: 'too many')),
    );
    await advance(tester, const Duration(milliseconds: 100));
    expect(motion(tester).shake, inExclusiveRange(0, 1));
    expect([for (final (type, _) in haptics) type], [heavy]);

    await advance(tester, const Duration(milliseconds: 400));
    expect(motion(tester).scan, 0);
    expect(shows(t.biometric_setup_locked), isTrue);
    expect(messageOpacity(tester, t.biometric_setup_locked), 1);
    expect(opened.last, isNull);

    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    expect(biometrics.prompts, hasLength(2));
    expect(messageOpacity(tester, t.biometric_setup_locked), 0);
  });

  testWidgets('another failure, and a preference that does not save, get '
      'their own messages', (tester) async {
    await open(tester);
    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    biometrics.prompts.last.complete(
      const Left(AuthError(code: 'NotAvailable', message: 'gone')),
    );
    await advance(tester, const Duration(milliseconds: 400));
    expect(shows(t.biometric_setup_failed), isTrue);

    biometrics.saveFails = true;
    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    biometrics.prompts.last.complete(const Right(true));
    await advance(tester, const Duration(milliseconds: 400));
    expect(shows(t.biometric_save_error), isTrue);
    expect(motion(tester).success, 0);
    expect(opened.last, isNull);
  });

  testWidgets('success saves the preference, turns the seal into a check '
      'and then into the Mooze coin, with a haptic on each, and the wallet '
      'opens with the coin', (tester) async {
    await open(tester);
    final providers = ProviderScope.containerOf(
      tester.element(find.byType(BiometricScene)),
    );
    expect(await providers.read(isBiometricEnabledProvider.future), isFalse);
    await tester.tap(button(t.biometric_method_generic));
    await advance(tester, const Duration(milliseconds: 300));
    biometrics.prompts.single.complete(const Right(true));

    Duration? start, end, doneAt;
    var heroBeforeCoin = false;
    while (opened.last == null && clock < const Duration(seconds: 6)) {
      await tester.pump(step);
      clock += step;
      if (find.byType(BiometricScene).evaluate().isEmpty) continue;
      final success = motion(tester).success;
      if (success > 0) start ??= clock;
      if (success == 1) end ??= clock;
      if (doneAt == null && shows(t.biometric_setup_done_title)) {
        doneAt = clock;
      }
      final hero = tester.widget<HeroMode>(
        find.ancestor(
          of: find.byType(StageHero),
          matching: find.byType(HeroMode),
        ),
      );
      if (hero.enabled && success < BiometricScene.edgeOnAt) {
        heroBeforeCoin = true;
      }
    }

    expect(biometrics.saved, [true]);
    // The rest of the app sees the new preference.
    expect(await providers.read(isBiometricEnabledProvider.future), isTrue);
    expect(opened.last, '/setup/wallet-import-loading');
    expect(opened.extras.last, StageEntrance.coinInPlace);
    expect(heroBeforeCoin, isFalse);
    expect([for (final (type, _) in haptics) type], [medium, light]);
    final duration = Motion.durationBiometricSuccess;
    final (_, peak) = haptics[0];
    final (_, edge) = haptics[1];
    expect(
      (peak - start! - duration * BiometricScene.peakAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    expect(
      (edge - start - duration * BiometricScene.edgeOnAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    expect(
      doneAt! - start,
      greaterThanOrEqualTo(duration * BiometricScene.revealAt - step * 2),
    );
    expect(end, isNotNull);
  });

  testWidgets('the page does not move when the caption changes', (
    tester,
  ) async {
    await open(tester);
    final before = tester.getRect(find.byType(BiometricScene));
    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    biometrics.prompts.single.complete(const Right(true));
    while (!shows(t.biometric_setup_done_title)) {
      expect(clock, lessThan(const Duration(seconds: 4)));
      await advance(tester, step);
    }
    expect(tester.getRect(find.byType(BiometricScene)), before);
  });

  testWidgets('"No thanks" opens the wallet without biometrics and without '
      'the coin', (tester) async {
    await open(tester);
    await tester.tap(find.text(t.common_no_thanks));
    await advance(tester, const Duration(milliseconds: 100));
    expect(opened.last, '/setup/wallet-import-loading');
    expect(opened.extras.last, isNull);
    expect(biometrics.prompts, isEmpty);
  });

  testWidgets('with reduced motion, nothing moves: the scan holds still, '
      'and success shows its end at once, with one light haptic', (
    tester,
  ) async {
    reduceMotion(tester);
    await open(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    // The beam rests across the middle of the seal. (The spinner of the
    // button is the button's own.)
    expect(motion(tester).scan, 1);
    expect(scene(tester).motion.sweep, 0.25);
    await advance(tester, const Duration(milliseconds: 500));
    expect(scene(tester).motion.sweep, 0.25);

    biometrics.prompts.single.complete(const Right(true));
    await tester.pump();
    await tester.pump();
    expect([for (final (type, _) in haptics) type], [light]);
    await advance(tester, const Duration(milliseconds: 100));
    expect(opened.last, '/setup/wallet-import-loading');
  });

  group('after the PIN is confirmed', () {
    /// Confirms the PIN 111111 on a device with [capabilities].
    Future<void> confirm(
      WidgetTester tester,
      BiometricCapabilities capabilities,
    ) async {
      SharedPreferences.setMockInitialValues({});
      usePhoneSize(tester);
      biometrics.enrolled = capabilities;
      await tester.pumpWidget(
        setupTestApp(
          router: GoRouter(
            initialLocation: '/confirm',
            routes: [
              GoRoute(
                path: '/confirm',
                builder: (_, _) => const ConfirmPinSetupScreen(pin: '111111'),
              ),
              opened.stub('/setup/biometric'),
              opened.stub('/setup/wallet-import-loading'),
            ],
          ),
          overrides: [
            biometricServiceProvider.overrideWithValue(biometrics),
            pinSetupRepositoryProvider.overrideWithValue(_FakePins()),
          ],
        ),
      );
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('1').last);
        await tester.pump();
      }
      await tester.tap(find.text(t.common_confirm));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('a device with a biometric offers it, with what it has', (
      tester,
    ) async {
      await confirm(tester, _faceId);
      expect(opened.last, '/setup/biometric');
      expect(opened.extras.last, same(_faceId));
    });

    testWidgets('a device with only a passcode goes straight to the wallet', (
      tester,
    ) async {
      await confirm(tester, _passcodeOnly);
      expect(opened.last, '/setup/wallet-import-loading');
    });
  });

  testWidgets('the Mooze coin flies on into the opening of the wallet as '
      'one coin, and the opening turns once it has landed', (tester) async {
    usePhoneSize(tester);
    recordHaptics(tester);
    final lifecycle = _FakeLifecycle();
    final boot = StreamController<BootState>.broadcast();
    final sync = StreamController<SyncState>.broadcast();
    addTearDown(boot.close);
    addTearDown(sync.close);
    final router = GoRouter(
      initialLocation: '/before',
      routes: [
        GoRoute(path: '/before', builder: (_, _) => const Scaffold()),
        _route('/setup/biometric'),
        _route('/setup/wallet-import-loading'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        overrides: [
          biometricServiceProvider.overrideWithValue(biometrics),
          appLifecycleControllerProvider.overrideWith((_) async => lifecycle),
          bootStateProvider.overrideWith((_) => boot.stream),
          syncStateProvider.overrideWith((_) => sync.stream),
        ],
      ),
    );
    router.go('/setup/biometric', extra: _fingerprint);
    await advance(tester, const Duration(milliseconds: 600));
    await tester.tap(button(t.biometric_method_generic));
    await tester.pump();
    biometrics.prompts.single.complete(const Right(true));

    final opening = find.byType(OpeningScene);
    while (opening.evaluate().isEmpty) {
      expect(clock, lessThan(const Duration(seconds: 6)));
      await advance(tester, step);
    }
    // The caption has left: only the coin is on the stage.
    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('captions')))
          .opacity,
      0,
    );
    final mooze = find.byWidgetPredicate(
      (widget) =>
          widget is GlyphToken &&
          widget.glyphPath == 'assets/images/onboarding/mooze_m.svg',
    );
    // In the air: one coin, which moves, while the seal it left is hidden
    // and the opening holds still.
    final seal = find.descendant(
      of: find.byType(BiometricScene),
      matching: find.byType(StageToken),
    );
    final path = <Offset>[];
    while (find.byType(BiometricScene).evaluate().isNotEmpty) {
      expect(mooze, findsOneWidget);
      expect(seal, findsNothing);
      path.add(tester.getCenter(mooze));
      expect(tester.widget<OpeningScene>(opening).motion.spin, 0);
      await advance(tester, step);
    }
    expect(path.length, greaterThan(2));
    expect((path.last - path.first).distance, greaterThan(10));
    expect(mooze, findsOneWidget);

    // Landed: the opening starts to turn.
    await advance(tester, const Duration(milliseconds: 400));
    expect(tester.widget<OpeningScene>(opening).motion.spin, greaterThan(0));
    // The opening of the wallet started meanwhile.
    expect(lifecycle.starts, hasLength(1));
  });
}
