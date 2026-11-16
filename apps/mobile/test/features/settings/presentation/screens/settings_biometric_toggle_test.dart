import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/biometric_service_provider.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/authentication/fake_biometrics.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  late FakeBiometrics biometrics;
  late ProviderContainer providers;

  setUp(() => biometrics = FakeBiometrics(fingerprintDevice));

  Future<void> open(WidgetTester tester) async {
    // Wide, so the test font fits the rows.
    tester.view.physicalSize = const Size(900, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    providers = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        biometricServiceProvider.overrideWithValue(biometrics),
      ],
    );
    addTearDown(providers.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providers,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// The switch of the biometric row.
  Finder biometricSwitch() => find.descendant(
    of: find.ancestor(
      of: find.text(t.settings_biometric_auth),
      matching: find.byType(LabelSettings),
    ),
    matching: find.byType(Switch),
  );

  testWidgets('quick taps on the switch open one prompt', (tester) async {
    await open(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(biometricSwitch());
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(biometrics.prompts, hasLength(1));
  });

  testWidgets('the auth prompt flag stays up while the prompt is open, '
      'whatever the taps', (tester) async {
    await open(tester);
    await tester.tap(biometricSwitch());
    await tester.pump(const Duration(milliseconds: 50));
    expect(providers.read(authPromptActiveProvider), isTrue);

    // Android answers a second prompt at once: one is in progress.
    await tester.tap(biometricSwitch());
    await tester.pump(const Duration(milliseconds: 50));
    for (final prompt in biometrics.prompts.skip(1)) {
      prompt.complete(
        const Left(AuthError(code: 'AlreadyInProgress', message: 'busy')),
      );
    }
    await tester.pump();
    expect(providers.read(authPromptActiveProvider), isTrue);

    biometrics.prompts.first.complete(const Right(true));
    await tester.pump();
    await tester.pump();
    expect(providers.read(authPromptActiveProvider), isFalse);
    expect(biometrics.saved, [true]);
  });

  testWidgets('two taps in one frame, before the switch turns off, open one '
      'prompt', (tester) async {
    await open(tester);
    await tester.tap(biometricSwitch());
    await tester.tap(biometricSwitch());
    await tester.pump();
    expect(biometrics.prompts, hasLength(1));
  });

  testWidgets('the switch takes no tap while the prompt is open, and takes '
      'taps again once it closes, even dismissed or failed', (tester) async {
    bool enabled() =>
        tester.widget<Switch>(biometricSwitch()).onChanged != null;
    await open(tester);
    expect(enabled(), isTrue);

    for (final answer in [
      const Right<AuthError, bool>(false),
      const Left<AuthError, bool>(AuthError(code: 'Failed', message: 'no')),
    ]) {
      await tester.tap(biometricSwitch());
      await tester.pump();
      expect(enabled(), isFalse);
      biometrics.prompts.last.complete(answer);
      await tester.pump();
      await tester.pump();
      expect(enabled(), isTrue);
    }
    expect(biometrics.prompts, hasLength(2));
    expect(biometrics.saved, isEmpty);
  });
}
