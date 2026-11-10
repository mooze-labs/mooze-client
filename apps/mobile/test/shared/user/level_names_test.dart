import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/current_limits_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/level_names.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  test('each level has its name in each language', () {
    final names = {
      'pt': ['Bronze', 'Prata', 'Ouro', 'Diamante'],
      'en': ['Bronze', 'Silver', 'Gold', 'Diamond'],
      'es': ['Bronce', 'Plata', 'Oro', 'Diamante'],
    };
    for (final MapEntry(key: language, value: expected) in names.entries) {
      final t = lookupAppLocalizations(Locale(language));
      expect([for (var i = 0; i < 4; i++) t.levelName(i)], expected);
      // Any other order is the first level.
      expect(t.levelName(-1), expected.first);
      expect(t.levelName(9), expected.first);
    }
  });

  /// [child] in Portuguese, with the wallet at the Gold level.
  Widget app(Widget child) => ProviderScope(
    overrides: [
      levelsProvider.overrideWith(
        (ref) async => const UserLevelsData(
          spendingLevel: 2,
          levelProgress: 0.5,
          allowedSpending: 1000,
          dailySpending: 0,
          currentLevelMinLimit: 20,
          currentLevelMaxLimit: 1000,
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('the limits card names the level and the next one in the '
      'language of the app', (tester) async {
    final t = lookupAppLocalizations(const Locale('pt'));
    await tester.pumpWidget(app(const CurrentLimitsCard()));
    await tester.pumpAndSettle();

    expect(find.text(t.wallet_levels_current_level('Ouro')), findsOneWidget);
    expect(
      find.text(t.wallet_levels_next_level_hint_named('Diamante')),
      findsOneWidget,
    );
    expect(find.textContaining('Gold'), findsNothing);
  });

  testWidgets('the level track names each level in the language of the '
      'app', (tester) async {
    await tester.pumpWidget(app(const UserLevelCard(currentLevel: 2)));
    await tester.pumpAndSettle();

    for (final name in ['Bronze', 'Prata', 'Ouro', 'Diamante']) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    for (final english in ['Silver', 'Gold', 'Diamond']) {
      expect(find.text(english), findsNothing, reason: english);
    }
  });
}
