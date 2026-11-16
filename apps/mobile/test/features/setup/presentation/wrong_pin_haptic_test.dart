import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/confirm_pin_setup.dart';
import 'package:mooze_mobile/features/setup/presentation/widgets/pin/pin_dots.dart';
import 'package:mooze_mobile/features/setup/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/authentication/fake_biometrics.dart';
import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const heavy = 'HapticFeedbackType.heavyImpact';
  late List<String> haptics;

  void recordHaptics(WidgetTester tester) {
    haptics = [];
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
  }

  int heavies() => haptics.where((h) => h == heavy).length;

  group('PinDots', () {
    late StateSetter set;
    late int errors;

    Future<void> pump(WidgetTester tester) async {
      recordHaptics(tester);
      errors = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return PinDots(length: 6, filled: 0, errorCount: errors);
              },
            ),
          ),
        ),
      );
    }

    /// The side offset of the shake: the outermost transform of the dots.
    double shift(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(PinDots),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .x;

    testWidgets('each wrong PIN shakes the dots with one heavy haptic', (
      tester,
    ) async {
      await pump(tester);
      expect(haptics, isEmpty);

      set(() => errors = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(heavies(), 1);
      expect(shift(tester), isNot(0));

      // A rebuild without a new error plays nothing.
      await tester.pump(const Duration(seconds: 1));
      set(() {});
      await tester.pump();
      expect(heavies(), 1);

      set(() => errors = 2);
      await tester.pump();
      expect(heavies(), 2);
    });

    testWidgets('with reduced motion, the dots do not shake, and the haptic '
        'still tells the error', (tester) async {
      reduceMotion(tester);
      await pump(tester);

      set(() => errors = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(heavies(), 1);
      expect(shift(tester), 0);
    });
  });

  group('a wrong PIN', () {
    GoRoute route(String path) => setupRoutes.whereType<GoRoute>().singleWhere(
      (route) => route.path == path,
    );

    Future<void> type(WidgetTester tester, String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.text(digit).last);
        await tester.pump();
      }
    }

    testWidgets('on the PIN check plays the haptic; the right PIN does not', (
      tester,
    ) async {
      usePhoneSize(tester);
      recordHaptics(tester);
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await AuthenticationService().createPin('111111');
      var confirmed = false;
      final router = GoRouter(
        initialLocation: '/before',
        routes: [
          GoRoute(path: '/before', builder: (_, _) => const Scaffold()),
          route('/setup/pin/verify'),
        ],
      );
      await tester.pumpWidget(
        setupTestApp(
          router: router,
          overrides: [
            biometricServiceProvider.overrideWithValue(
              FakeBiometrics(passcodeDevice),
            ),
          ],
        ),
      );
      router.push(
        '/setup/pin/verify',
        extra: VerifyPinArgs(
          onPinConfirmed: () => confirmed = true,
          forceAuth: true,
        ),
      );
      await settle(tester);

      await type(tester, '222222');
      await tester.tap(find.text(t.common_continue));
      await settle(tester);
      expect(heavies(), 1);
      expect(confirmed, isFalse);

      await type(tester, '111111');
      await tester.tap(find.text(t.common_continue));
      await tester.pump(const Duration(seconds: 2));
      expect(confirmed, isTrue);
      expect(heavies(), 1);
    });

    testWidgets('on the confirmation of a new PIN plays the haptic', (
      tester,
    ) async {
      usePhoneSize(tester);
      recordHaptics(tester);
      await tester.pumpWidget(
        setupTestApp(
          router: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const ConfirmPinSetupScreen(pin: '111111'),
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      await type(tester, '222222');
      await tester.tap(find.text(t.common_confirm));
      await settle(tester);
      expect(heavies(), 1);
    });
  });
}
