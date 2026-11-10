import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Records the routes that a setup screen opened.
class OpenedRoutes {
  final List<String> locations = [];
  final List<Object?> extras = [];

  String? get last => locations.isEmpty ? null : locations.last;

  /// A route that only records that it opened.
  GoRoute stub(String path) => GoRoute(
    path: path,
    builder: (_, state) {
      locations.add(state.uri.toString());
      extras.add(state.extra);
      return Scaffold(body: Text('opened $path'));
    },
  );
}

/// The app around a setup screen: the dark theme, Portuguese texts and a
/// router.
Widget setupTestApp({
  required GoRouter router,
  List<Override> overrides = const [],
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Theme(data: AppTheme.darkTheme(context), child: child!),
      ),
    ),
  );
}

/// Sizes the test window as a common phone: 390 × 844 pt.
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps frames for routes and entrances. Some screens animate without
/// end, so `pumpAndSettle` would not return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
