import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/providers/cache_info_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Bitcoin saved 2 minutes ago, USDT 45 minutes ago, and no DePix.
final _saved = [
  AssetCacheInfo(
    asset: Asset.btc,
    hasCache: true,
    ageInMinutes: 2,
    lastPrice: 500000,
  ),
  AssetCacheInfo(
    asset: Asset.usdt,
    hasCache: true,
    ageInMinutes: 45,
    lastPrice: 5.37,
  ),
  AssetCacheInfo(asset: Asset.depix, hasCache: false),
];

void main() {
  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('pt'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cacheInfoProvider.overrideWith((ref) async => _saved)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => OfflinePriceInfoOverlay.show(context),
                child: const Text('offline'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens as a floating glass sheet and the close button closes '
      'it', (tester) async {
    await open(tester);

    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.text('App offline'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
  });

  testWidgets('shows each saved price with its age, and no N/A', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('R\$ 500.000,00'), findsOneWidget);
    expect(find.text('há 2min'), findsOneWidget);
    expect(find.text('Recente'), findsOneWidget);

    expect(find.text('R\$ 5,37'), findsOneWidget);
    expect(find.text('Muito antigo'), findsOneWidget);

    // DePix has no saved price.
    expect(find.text('Sem cache'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('N/A'), findsNothing);

    expect(
      find.text(
        'Os preços serão atualizados automaticamente quando a conexão for '
        'restaurada',
      ),
      findsOneWidget,
    );
  });

  testWidgets('speaks the language of the app', (tester) async {
    await open(tester, locale: const Locale('en'));

    expect(find.text('Saved prices'), findsOneWidget);
    expect(find.text('2m ago'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Very old'), findsOneWidget);
    expect(find.text('Not saved'), findsOneWidget);
    expect(
      find.text('Prices update automatically when the connection is back'),
      findsOneWidget,
    );
    expect(find.text('Preços salvos'), findsNothing);
  });
}
