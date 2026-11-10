import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/wallet_levels_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// The levels open from the menu and from the Pix hub. Back must return to
/// the screen that opened them.
Widget _host(String opener) {
  final router = GoRouter(
    initialLocation: opener,
    routes: [
      GoRoute(
        path: '/menu',
        builder: (_, _) => const Scaffold(body: Text('menu')),
      ),
      GoRoute(
        path: '/pix',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/wallet-levels'),
            child: const Text('pix hub'),
          ),
        ),
      ),
      GoRoute(
        path: '/wallet-levels',
        builder: (_, _) => const WalletLevelsScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      // The levels never load: the test only needs the app bar.
      walletLevelsProvider.overrideWith(
        (ref) => Completer<List<WalletLevelEntity>>().future,
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      builder: (context, child) =>
          Theme(data: AppTheme.darkTheme(context), child: child!),
    ),
  );
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('back from the levels returns to the Pix hub', (tester) async {
    await tester.pumpWidget(_host('/pix'));
    await _frames(tester);

    await tester.tap(find.text('pix hub'));
    await _frames(tester);
    expect(find.byType(WalletLevelsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await _frames(tester);

    expect(find.text('pix hub'), findsOneWidget);
    expect(find.text('menu'), findsNothing);
  });

  testWidgets('a direct link falls back to the menu', (tester) async {
    await tester.pumpWidget(_host('/wallet-levels'));
    await _frames(tester);

    await tester.tap(find.byType(BackButton));
    await _frames(tester);

    expect(find.text('menu'), findsOneWidget);
  });
}
