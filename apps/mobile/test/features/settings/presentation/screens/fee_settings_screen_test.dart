import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/fee_settings_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

const _warning =
    'Com a taxa econômica, a transação Bitcoin pode levar horas ou até dias '
    'para confirmar, e o swap só termina depois disso. Se a rede descartar a '
    'transação antes de confirmar, o valor é devolvido para a sua carteira e '
    'você precisa fazer o swap de novo.';

void main() {
  late SharedPreferences prefs;

  Future<void> open(
    WidgetTester tester, {
    bool enabled = false,
    bool customFee = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      PegLowFeeEnabledNotifier.key: enabled,
      SendCustomFeeEnabledNotifier.key: customFee,
    });
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: const FeeSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  final lowFeeSwitch = find.widgetWithText(
    SwitchListTile,
    'Permitir taxa econômica',
  );
  final customFeeSwitch = find.widgetWithText(
    SwitchListTile,
    'Permitir taxa personalizada',
  );

  bool switchOn(WidgetTester tester, [Finder? row]) =>
      tester.widget<SwitchListTile>(row ?? lowFeeSwitch).value;

  Future<void> tapSwitch(WidgetTester tester, [Finder? row]) async {
    await tester.tap(row ?? lowFeeSwitch);
    await tester.pumpAndSettle();
  }

  testWidgets('groups the fee settings by where they apply', (tester) async {
    await open(tester);

    expect(find.text('Taxas'), findsOneWidget);
    expect(find.text('SWAP'), findsOneWidget);
    expect(find.text('ENVIAR ATIVOS'), findsOneWidget);
    expect(lowFeeSwitch, findsOneWidget);
    expect(customFeeSwitch, findsOneWidget);
  });

  testWidgets('starts off, with no warning', (tester) async {
    await open(tester);

    expect(find.text('Permitir taxa econômica'), findsOneWidget);
    expect(
      find.text(
        'Mostra a velocidade Econômica ao confirmar um swap entre ativos',
      ),
      findsOneWidget,
    );
    expect(switchOn(tester), isFalse);
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('turning it on asks first, and Cancel keeps it off', (
    tester,
  ) async {
    await open(tester);

    await tapSwitch(tester);

    // A floating glass sheet with the warning icon, not a dialog.
    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.descendant(
        of: find.byType(GlassSheet),
        matching: find.byWidgetPredicate(
          (w) => w is PixIcon && w.icon == PixIcons.warning,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Ativar taxa econômica?'), findsOneWidget);
    expect(find.text(_warning), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(switchOn(tester), isFalse);
    expect(prefs.getBool(PegLowFeeEnabledNotifier.key), isFalse);
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('closing the sheet keeps it off', (tester) async {
    await open(tester);

    await tapSwitch(tester);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
    expect(switchOn(tester), isFalse);
    expect(prefs.getBool(PegLowFeeEnabledNotifier.key), isFalse);
  });

  testWidgets('accepting the warning turns it on and keeps the warning', (
    tester,
  ) async {
    await open(tester);

    await tapSwitch(tester);
    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();

    expect(switchOn(tester), isTrue);
    expect(prefs.getBool(PegLowFeeEnabledNotifier.key), isTrue);
    // The dialog closed; the warning stays under the switch.
    expect(find.text('Ativar taxa econômica?'), findsNothing);
    expect(find.text(_warning), findsOneWidget);
  });

  testWidgets('turning it off asks nothing', (tester) async {
    await open(tester, enabled: true);
    expect(find.text(_warning), findsOneWidget);

    await tapSwitch(tester);

    expect(find.text('Ativar taxa econômica?'), findsNothing);
    expect(switchOn(tester), isFalse);
    expect(prefs.getBool(PegLowFeeEnabledNotifier.key), isFalse);
    expect(find.text(_warning), findsNothing);
  });

  group('custom fee', () {
    testWidgets('starts off', (tester) async {
      await open(tester);

      expect(
        find.text(
          'Mostra a opção Personalizada na velocidade de um envio em Bitcoin '
          'on-chain',
        ),
        findsOneWidget,
      );
      expect(switchOn(tester, customFeeSwitch), isFalse);
    });

    testWidgets('turns on at once, with no sheet, and stays on', (
      tester,
    ) async {
      await open(tester);

      await tapSwitch(tester, customFeeSwitch);

      expect(find.byType(GlassSheet), findsNothing);
      expect(switchOn(tester, customFeeSwitch), isTrue);
      expect(prefs.getBool(SendCustomFeeEnabledNotifier.key), isTrue);
      // The economic fee of the swap does not change.
      expect(switchOn(tester), isFalse);
    });

    testWidgets('turns off', (tester) async {
      await open(tester, customFee: true);

      await tapSwitch(tester, customFeeSwitch);

      expect(switchOn(tester, customFeeSwitch), isFalse);
      expect(prefs.getBool(SendCustomFeeEnabledNotifier.key), isFalse);
    });
  });
}
