import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/operations/pix_limits_screen.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          levelsProvider.overrideWith(
            (ref) async => const UserLevelsData(
              spendingLevel: 0,
              levelProgress: 0,
              allowedSpending: 20,
              dailySpending: 0,
              currentLevelMinLimit: 20,
              currentLevelMaxLimit: 250,
              absoluteMinLimit: 20,
              absoluteMaxLimit: 3000,
              remainingLimit: 5000,
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: const PixLimitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The user tapped to read how the limits work. They may want to leave at
  // once, so the sheet does not hold them for the reading time.
  testWidgets('how the limits work opens in a floating glass sheet that '
      'closes at once', (tester) async {
    await open(tester);

    await tester.tap(find.text(t.pix_hub_limits_how_it_works));
    await tester.pumpAndSettle();

    expect(find.byType(PixLimitsInfoSheet), findsOneWidget);
    expect(find.byType(GlassSheet), findsOneWidget);
    final button = tester.widget<PrimaryButton>(
      find.descendant(
        of: find.byType(PixLimitsInfoSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(button.isEnabled, isTrue);

    await tester.tap(find.text(t.common_understood));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsNothing);
  });
}
