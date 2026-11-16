import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_screen_scaffold.dart';
import 'package:mooze_mobile/features/setup/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/authentication/fake_biometrics.dart';
import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

GoRoute _route(String path) =>
    setupRoutes.whereType<GoRoute>().singleWhere((route) => route.path == path);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);
  const medium = 'HapticFeedbackType.mediumImpact';
  const light = 'HapticFeedbackType.lightImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';
  const finale = BiometricFinale.check;

  late FakeBiometrics biometrics;
  late List<(String, Duration)> haptics;
  late Duration clock;
  Duration? confirmedAt;

  setUp(() {
    biometrics = FakeBiometrics(fingerprintDevice, enabled: true);
    haptics = [];
    clock = Duration.zero;
    confirmedAt = null;
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

  /// Pushes the PIN check of the app over another screen, as a flow of the
  /// settings does, on a device with [capabilities], and lets its page
  /// start to come in.
  Future<void> push(
    WidgetTester tester, {
    BiometricCapabilities capabilities = fingerprintDevice,
  }) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'hashedPin': 'hash',
      'pinSalt': 'salt',
    });
    usePhoneSize(tester);
    recordHaptics(tester);
    biometrics.enrolled = capabilities;
    final router = GoRouter(
      initialLocation: '/before',
      routes: [
        GoRoute(path: '/before', builder: (_, _) => const Scaffold()),
        _route('/setup/pin/verify'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        overrides: [biometricServiceProvider.overrideWithValue(biometrics)],
      ),
    );
    router.push(
      '/setup/pin/verify',
      extra: VerifyPinArgs(
        onPinConfirmed: () => confirmedAt = clock,
        forceAuth: true,
      ),
    );
    await advance(tester, step * 3);
  }

  /// [push], and the page transition.
  Future<void> open(
    WidgetTester tester, {
    BiometricCapabilities capabilities = fingerprintDevice,
  }) async {
    await push(tester, capabilities: capabilities);
    await advance(tester, const Duration(milliseconds: 600));
  }

  BiometricScene scene(WidgetTester tester) =>
      tester.widget<BiometricScene>(find.byType(BiometricScene));

  BiometricMotion motion(WidgetTester tester) => scene(tester).motion;

  PinTextAction usePin(WidgetTester tester) => tester.widget<PinTextAction>(
    find.widgetWithText(PinTextAction, t.pin_use_pin),
  );

  testWidgets('the seal comes in once the page is in place, and scans '
      'while the prompt is up', (tester) async {
    await push(tester);
    // The prompt is up at once; the seal waits for the page.
    expect(biometrics.prompts, hasLength(1));
    expect(scene(tester).finale, finale);
    expect(motion(tester).ambient, 0);

    await advance(tester, const Duration(milliseconds: 600));
    expect(motion(tester).ambient, greaterThan(0));
    expect(motion(tester).scan, 1);
    final sweep = motion(tester).sweep;
    await advance(tester, const Duration(milliseconds: 200));
    expect(motion(tester).sweep, isNot(sweep));
  });

  testWidgets('the seal shows the biometric of the device', (tester) async {
    await open(tester, capabilities: faceIdDevice);
    expect(scene(tester).kind, BiometricKind.face);
  });

  testWidgets('a dismissed prompt lets the seal rest, and the button tries '
      'again', (tester) async {
    await open(tester);
    biometrics.prompts.single.complete(const Right(false));
    await advance(tester, const Duration(milliseconds: 400));

    expect(motion(tester).scan, 0);
    expect(motion(tester).success, 0);
    expect(haptics, isEmpty);
    expect(confirmedAt, isNull);
    await tester.tap(find.text(t.pin_use_biometric));
    await tester.pump();
    expect(biometrics.prompts, hasLength(2));
  });

  testWidgets('a failure shakes the seal with a heavy haptic', (tester) async {
    await open(tester);
    biometrics.prompts.single.complete(
      const Left(AuthError(code: 'NotAvailable', message: 'gone')),
    );
    await advance(tester, const Duration(milliseconds: 100));
    expect(motion(tester).shake, inExclusiveRange(0, 1));
    expect([for (final (type, _) in haptics) type], [heavy]);

    await advance(tester, const Duration(milliseconds: 600));
    expect(motion(tester).scan, 0);
    expect(motion(tester).success, 0);
    expect(confirmedAt, isNull);
  });

  testWidgets('a success draws the check with a medium haptic at its peak, '
      'then confirms the PIN while the shockwave still spreads', (
    tester,
  ) async {
    await open(tester);
    biometrics.prompts.single.complete(const Right(true));

    Duration? start, checkDrawnAt;
    var pinWhileCheck = false;
    double? successAtConfirm;
    while (confirmedAt == null && clock < const Duration(seconds: 3)) {
      await tester.pump(step);
      clock += step;
      final success = motion(tester).success;
      if (success > 0) {
        start ??= clock;
        if (usePin(tester).onPressed != null) pinWhileCheck = true;
      }
      if (success >= finale.checkDraws.$2) checkDrawnAt ??= clock;
      if (confirmedAt != null) successAtConfirm = success;
    }

    final duration = finale.duration;
    expect(
      (confirmedAt! - start! - duration * finale.handOffAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    expect(checkDrawnAt, lessThan(confirmedAt!));
    expect(successAtConfirm, lessThan(1));
    expect(pinWhileCheck, isFalse);
    expect([for (final (type, _) in haptics) type], [medium]);
    final (_, peak) = haptics.single;
    expect(
      (peak - start - duration * finale.peakAt).abs(),
      lessThanOrEqualTo(step * 2),
    );
    // The seal rests with its check.
    await advance(tester, duration);
    expect(motion(tester).success, 1);
  });

  testWidgets('with reduced motion, the check shows at once, with a light '
      'haptic, and the PIN is confirmed at once', (tester) async {
    reduceMotion(tester);
    await open(tester);
    expect(motion(tester).ambient, 1);
    expect(motion(tester).scan, 1);
    biometrics.prompts.single.complete(const Right(true));
    await tester.pump();

    expect(motion(tester).success, 1);
    expect(confirmedAt, clock);
    expect([for (final (type, _) in haptics) type], [light]);
  });

  testWidgets('from the PIN, the fingerprint key brings the seal back in, '
      'and it scans again', (tester) async {
    await open(tester);
    biometrics.prompts.single.complete(const Right(false));
    await advance(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(t.pin_use_pin));
    await advance(tester, const Duration(milliseconds: 400));
    expect(find.byType(BiometricScene), findsNothing);

    await tester.tap(find.byIcon(Icons.fingerprint_rounded));
    await advance(tester, step);
    expect(biometrics.prompts, hasLength(2));
    expect(motion(tester).ambient, lessThan(0.05));
    await advance(tester, const Duration(milliseconds: 400));
    expect(motion(tester).ambient, greaterThan(0.05));
    expect(motion(tester).scan, 1);
  });
}
