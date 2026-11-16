import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mooze_mobile/app/session/lock_seal_provider.dart';
import 'package:mooze_mobile/app/session/privacy_shield_controller.dart';
import 'package:mooze_mobile/app/session/session_lock_controller.dart';
import 'package:mooze_mobile/app/session/session_lock_state.dart';
import 'package:mooze_mobile/app/session/widgets/privacy_shield_overlay.dart';
import 'package:mooze_mobile/app/session/widgets/session_lock_gate.dart';
import 'package:mooze_mobile/app/session/widgets/wallet_lock_overlay.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/authentication/fake_biometrics.dart';
import '../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);
  const medium = 'HapticFeedbackType.mediumImpact';
  const light = 'HapticFeedbackType.lightImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';
  const finale = BiometricFinale.check;

  late FakeBiometrics biometrics;
  late ProviderContainer providers;
  late List<(String, Duration)> haptics;
  late Duration clock;
  Duration? unlockedAt;

  setUp(() {
    biometrics = FakeBiometrics(fingerprintDevice, enabled: true);
    haptics = [];
    clock = Duration.zero;
    unlockedAt = null;
  });

  Future<void> advance(WidgetTester tester, Duration time) async {
    final end = clock + time;
    while (clock < end) {
      await tester.pump(step);
      clock += step;
    }
  }

  /// The app under its global cover, as `main.dart` stacks them.
  Widget app(Widget cover) => UncontrolledProviderScope(
    container: providers,
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme(context),
        child: Stack(children: [child!, cover]),
      ),
      home: const Scaffold(body: Center(child: Text('wallet'))),
    ),
  );

  Widget overlay({
    required bool locked,
    BiometricKind? kind = BiometricKind.fingerprint,
  }) => app(
    WalletLockOverlay(
      showCover: true,
      showAuthentication: locked,
      onAuthenticated: () => unlockedAt = clock,
      sealKind: kind,
    ),
  );

  Future<void> start(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    providers = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        biometricServiceProvider.overrideWithValue(biometrics),
      ],
    );
    addTearDown(providers.dispose);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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

  /// The cover was up while the app was away; the app comes back locked,
  /// and the lock prompts the biometric.
  Future<void> resumeLocked(WidgetTester tester) async {
    await start(tester);
    await tester.pumpWidget(overlay(locked: false));
    await tester.pumpWidget(overlay(locked: true));
    await advance(tester, const Duration(milliseconds: 400));
  }

  bool locked() =>
      providers.read(sessionLockControllerProvider) == SessionLockState.locked;

  /// The session is locked, and the app comes back to its gate, whose lock
  /// prompts the biometric.
  Future<void> lockedGate(WidgetTester tester) async {
    await start(tester);
    providers.read(sessionLockControllerProvider.notifier)
      ..debugSetBackgroundedAt(DateTime(2000))
      ..onResumed();
    expect(locked(), isTrue);
    await tester.pumpWidget(app(const SessionLockGate()));
    await advance(tester, const Duration(milliseconds: 400));
  }

  /// Whether the cover is off the screen.
  bool coverGone(WidgetTester tester) => tester
      .widget<Offstage>(
        find
            .descendant(
              of: find.byType(WalletLockOverlay),
              matching: find.byType(Offstage, skipOffstage: false),
              skipOffstage: false,
            )
            .first,
      )
      .offstage;

  BiometricMotion motion(WidgetTester tester) =>
      tester.widget<BiometricScene>(find.byType(BiometricScene)).motion;

  /// The opacity the action with [label] is going to.
  double action(WidgetTester tester, String label) => tester
      .widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  /// The opacity of the whole lock face.
  double cover(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(WalletLockOverlay),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  group('the cover of the app switcher', () {
    testWidgets('shows the seal at rest to a user of biometrics', (
      tester,
    ) async {
      await start(tester);
      await tester.pumpWidget(overlay(locked: false));
      await advance(tester, const Duration(milliseconds: 500));

      final scene = tester.widget<BiometricScene>(find.byType(BiometricScene));
      expect(scene.kind, BiometricKind.fingerprint);
      expect(scene.finale, finale);
      expect(scene.motion.ambient, 1);
      expect(scene.motion.scan, 0);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      // It offers nothing to tap.
      expect(action(tester, t.pin_use_biometric), 0);
      expect(action(tester, t.pin_use_pin), 0);
    });

    testWidgets('shows the padlock to a user of a PIN alone', (tester) async {
      await start(tester);
      await tester.pumpWidget(overlay(locked: false, kind: null));
      expect(find.byType(BiometricScene), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  testWidgets('back in the app, the same seal comes alive: it stays in '
      'place, scans while the prompt is up, and the actions fade in', (
    tester,
  ) async {
    await start(tester);
    await tester.pumpWidget(overlay(locked: false));
    final place = tester.getRect(find.byType(StageToken));

    await tester.pumpWidget(overlay(locked: true));
    expect(tester.getRect(find.byType(StageToken)), place);
    expect(motion(tester).scan, 0);

    await advance(tester, const Duration(milliseconds: 400));
    expect(biometrics.prompts, hasLength(1));
    expect(motion(tester).scan, 1);
    expect(action(tester, t.pin_use_biometric), 1);
    expect(action(tester, t.pin_use_pin), 1);
    expect(tester.getRect(find.byType(StageToken)), place);
  });

  testWidgets('a failure shakes the seal with a heavy haptic, and the '
      'button tries again', (tester) async {
    await resumeLocked(tester);
    biometrics.prompts.single.complete(
      const Left(AuthError(code: 'NotAvailable', message: 'gone')),
    );
    await advance(tester, const Duration(milliseconds: 100));
    expect(motion(tester).shake, inExclusiveRange(0, 1));
    expect([for (final (type, _) in haptics) type], [heavy]);

    await advance(tester, const Duration(milliseconds: 600));
    expect(motion(tester).scan, 0);
    expect(cover(tester), 1);
    expect(unlockedAt, isNull);
    await tester.tap(find.text(t.pin_use_biometric));
    await tester.pump();
    expect(biometrics.prompts, hasLength(2));
  });

  testWidgets('a dismissed prompt lets the seal rest, with the actions', (
    tester,
  ) async {
    await resumeLocked(tester);
    biometrics.prompts.single.complete(const Right(false));
    await advance(tester, const Duration(milliseconds: 400));
    expect(motion(tester).scan, 0);
    expect(motion(tester).success, 0);
    expect(haptics, isEmpty);
    expect(action(tester, t.pin_use_biometric), 1);
    expect(unlockedAt, isNull);
  });

  testWidgets('with reduced motion, the check shows at once, with a light '
      'haptic, and the cover goes at once', (tester) async {
    reduceMotion(tester);
    await resumeLocked(tester);
    expect(motion(tester).scan, 1);
    biometrics.prompts.single.complete(const Right(true));
    await tester.pump();

    expect(motion(tester).success, 1);
    expect(unlockedAt, clock);
    expect(cover(tester), 0);
    expect([for (final (type, _) in haptics) type], [light]);
  });

  testWidgets('after the PIN, the session unlocks, and the cover fades away '
      'too', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await resumeLocked(tester);
    await AuthenticationService().createPin('111111');
    biometrics.prompts.single.complete(const Right(false));
    await advance(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(t.pin_use_pin));
    await advance(tester, const Duration(milliseconds: 600));
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('1').last);
      await tester.pump();
    }
    await tester.tap(find.text(t.common_continue));

    Duration? goneAt;
    while (goneAt == null && clock < const Duration(seconds: 4)) {
      await tester.pump(step);
      clock += step;
      if (unlockedAt != null && cover(tester) == 0) goneAt = clock;
    }
    expect(
      (goneAt! - unlockedAt! - Durations.short4).abs(),
      lessThanOrEqualTo(step * 2),
    );
  });

  group('the gate', () {
    testWidgets('shows the seal of the device on the cover', (tester) async {
      biometrics.enrolled = faceIdDevice;
      await start(tester);
      await tester.pumpWidget(app(const SessionLockGate()));
      await tester.pump();
      providers
          .read(privacyShieldControllerProvider.notifier)
          .onLeavingForeground();
      await tester.pump();

      expect(
        tester.widget<BiometricScene>(find.byType(BiometricScene)).kind,
        BiometricKind.face,
      );
      expect(find.byType(PrivacyShieldOverlay), findsOneWidget);
    });

    testWidgets('unlocks the session the moment the biometric lets the '
        'user in; the cover then draws the check with a medium haptic at '
        'its peak, and fades away over the wallet', (tester) async {
      await lockedGate(tester);
      biometrics.prompts.single.complete(const Right(true));
      await tester.pump();
      expect(locked(), isFalse);
      expect(coverGone(tester), isFalse);

      Duration? start, fadeFrom, goneAt;
      double? actionsAtFade;
      while (goneAt == null && clock < const Duration(seconds: 3)) {
        await tester.pump(step);
        clock += step;
        if (coverGone(tester)) {
          goneAt = clock;
          break;
        }
        if (motion(tester).success > 0) start ??= clock;
        if (fadeFrom == null && cover(tester) < 1) {
          fadeFrom = clock;
          actionsAtFade = action(tester, t.pin_use_biometric);
        }
      }

      final duration = finale.duration;
      expect(
        (fadeFrom! - start! - duration * finale.handOffAt).abs(),
        lessThanOrEqualTo(step * 2),
      );
      expect(
        (goneAt! - fadeFrom - Durations.short4).abs(),
        lessThanOrEqualTo(step * 2),
      );
      expect([for (final (type, _) in haptics) type], [medium]);
      final (_, peak) = haptics.single;
      expect(
        (peak - start - duration * finale.peakAt).abs(),
        lessThanOrEqualTo(step * 2),
      );
      // The actions left as the check came.
      expect(actionsAtFade, 0);
      expect(find.text('wallet').hitTestable(), findsOneWidget);
    });

    testWidgets('while the privacy shield is up, a cover on its way out '
        'shows whole', (tester) async {
      await lockedGate(tester);
      biometrics.prompts.single.complete(const Right(true));
      await advance(tester, finale.duration * finale.handOffAt);
      await advance(tester, const Duration(milliseconds: 100));
      expect(cover(tester), inExclusiveRange(0, 1));

      final shield = providers.read(privacyShieldControllerProvider.notifier);
      shield.onLeavingForeground();
      await tester.pump();
      expect(cover(tester), 1);

      shield.onResumed();
      await advance(tester, const Duration(milliseconds: 300));
      expect(coverGone(tester), isTrue);
    });

    testWidgets('leaving the app while the cover goes locks it again, as '
        'any trip out of an unlocked app, and a fresh lock prompts again', (
      tester,
    ) async {
      await lockedGate(tester);
      biometrics.prompts.single.complete(const Right(true));
      await advance(tester, const Duration(milliseconds: 300));
      expect(locked(), isFalse);

      // The app goes away and comes back, as the lifecycle observer tells
      // it. The lock comes at once, by default.
      final shield = providers.read(privacyShieldControllerProvider.notifier);
      final session = providers.read(sessionLockControllerProvider.notifier);
      shield.onLeavingForeground();
      session.onBackgrounded();
      await tester.pump();
      session.onResumed();
      shield.onResumed();
      await tester.pump();

      expect(locked(), isTrue);
      expect(cover(tester), 1);
      expect(motion(tester).success, 0);
      await advance(tester, const Duration(milliseconds: 400));
      expect(biometrics.prompts, hasLength(2));
      expect(motion(tester).scan, 1);
      await advance(tester, const Duration(seconds: 1));
      expect(coverGone(tester), isFalse);
      expect(locked(), isTrue);
    });
  });

  group('the kind of the seal of the lock', () {
    Future<BiometricKind?> kindOf(
      BiometricCapabilities capabilities, {
      required bool enabled,
    }) async {
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(
            FakeBiometrics(capabilities, enabled: enabled),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(lockSealKindProvider.future);
    }

    test(
      'is the biometric of the device, when the user unlocks with it',
      () async {
        expect(await kindOf(faceIdDevice, enabled: true), BiometricKind.face);
        expect(
          await kindOf(fingerprintDevice, enabled: true),
          BiometricKind.fingerprint,
        );
      },
    );

    test('is none for a PIN alone', () async {
      expect(await kindOf(fingerprintDevice, enabled: false), isNull);
      expect(await kindOf(passcodeDevice, enabled: true), isNull);
    });

    test('follows the preference', () async {
      final service = FakeBiometrics(fingerprintDevice);
      final container = ProviderContainer(
        overrides: [biometricServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final listened = container.listen(lockSealKindProvider, (_, _) {});
      expect(await container.read(lockSealKindProvider.future), isNull);

      service.enabled = true;
      container.invalidate(isBiometricEnabledProvider);
      expect(
        await container.read(lockSealKindProvider.future),
        BiometricKind.fingerprint,
      );
      listened.close();
    });
  });
}
