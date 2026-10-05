import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

/// Locale used by widget tests. The expected strings come from app_pt.arb.
const testLocale = Locale('pt');

/// Wraps [home] in a MaterialApp with the app localizations and theme.
///
/// Widgets call `AppLocalizations.of(context)` and `context.appColors`.
/// Both need configuration on the MaterialApp.
Widget wrapForTest(Widget home) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.dark().copyWith(extensions: const [AppExtraColors.dark]),
    home: home,
  );
}
