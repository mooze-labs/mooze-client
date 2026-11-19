import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/all_assets/all_assets_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/all_assets/pinnable_asset_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quotes with fixed prices, and no network.
class _FakeQuotes extends StateNotifier<PriceQuotes>
    implements PriceQuotesNotifier {
  _FakeQuotes()
    : super(
        PriceQuotes(
          currency: Currency.brl,
          quotes: {
            for (final asset in const [Asset.btc, Asset.usdt, Asset.depix])
              asset: PriceQuote(
                asset: asset,
                currency: Currency.brl,
                price: 100,
                fetchedAt: DateTime(2026, 11, 7),
              ),
          },
          lastSuccessAt: null,
          warming: false,
          refreshing: false,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// The pins as the app saves them, by asset name.
  List<String>? saved() => _prefs?.getStringList('favorite_assets');

  group('FavoriteAssetsNotifier', () {
    Future<FavoriteAssetsNotifier> load(List<String>? pins) async {
      SharedPreferences.setMockInitialValues({
        if (pins != null) 'favorite_assets': pins,
      });
      _prefs = await SharedPreferences.getInstance();
      final notifier = FavoriteAssetsNotifier();
      // The pins load from the disk in the constructor.
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    test('the last pinned asset stays: the home shows at least one', () async {
      final favorites = await load(['Bitcoin']);
      expect(favorites.state, [Asset.btc]);

      favorites.toggleFavorite(Asset.btc);
      await Future<void>.delayed(Duration.zero);

      expect(favorites.state, [Asset.btc]);
      expect(saved(), ['Bitcoin']);
    });

    test('an empty list saved by an earlier version loads the default '
        'pins', () async {
      final favorites = await load([]);

      expect(favorites.state, [Asset.btc, Asset.usdt]);
      expect(saved(), [Asset.btc.name, Asset.usdt.name]);
    });

    test('a new order is saved, and an empty one is ignored', () async {
      final favorites = await load(['Bitcoin', 'USDT']);

      favorites.setFavorites([Asset.usdt, Asset.btc]);
      await Future<void>.delayed(Duration.zero);
      expect(favorites.state, [Asset.usdt, Asset.btc]);
      expect(saved(), [Asset.usdt.name, Asset.btc.name]);

      favorites.setFavorites([]);
      await Future<void>.delayed(Duration.zero);
      expect(favorites.state, [Asset.usdt, Asset.btc]);
    });

    test('a third pin takes the place of the second, and the first stays '
        'first', () async {
      final favorites = await load(['Bitcoin', 'USDT']);

      favorites.toggleFavorite(Asset.depix);
      await Future<void>.delayed(Duration.zero);

      expect(favorites.state, [Asset.btc, Asset.depix]);
      expect(saved(), [Asset.btc.name, Asset.depix.name]);
    });

    test('of two pins, either one can still be unpinned', () async {
      final favorites = await load(['Bitcoin', 'USDT']);

      favorites.toggleFavorite(Asset.btc);
      await Future<void>.delayed(Duration.zero);

      expect(favorites.state, [Asset.usdt]);
    });
  });

  group('AllAssetsScreen', () {
    late ProviderContainer container;

    Future<void> open(
      WidgetTester tester,
      List<String> pins, {
      Brightness brightness = Brightness.dark,
      Size size = const Size(390, 844),
      double textScale = 1,
    }) async {
      SharedPreferences.setMockInitialValues({'favorite_assets': pins});
      _prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      container = ProviderContainer(
        overrides: [
          priceQuotesProvider.overrideWith((ref) => _FakeQuotes()),
          currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
          assetPriceHistoryProvider.overrideWith(
            (ref, asset) async => const Right([90.0, 95.0, 100.0]),
          ),
          priceHistoryFetcherProvider.overrideWithValue(
            (params) async => const Left('offline'),
          ),
          isOnlineProvider.overrideWith((ref) => true),
          isUsingCacheProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Theme(
                data: brightness == Brightness.dark
                    ? AppTheme.darkTheme(context)
                    : AppTheme.lightTheme(context),
                child: child!,
              ),
            ),
            home: const AllAssetsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder handles() => find.byIcon(Icons.drag_indicator_rounded);

    /// The star button of [asset].
    IconButton star(WidgetTester tester, Asset asset) => tester.widget(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is PinStarButton && w.asset == asset,
        ),
        matching: find.byType(IconButton),
      ),
    );

    testWidgets('with two pins, each pinned row has a drag handle and the '
        'hint says how to reorder', (tester) async {
      await open(tester, ['Bitcoin', 'USDT']);

      expect(handles(), findsNWidgets(2));
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text(t.wallet_all_assets_hint_two), findsOneWidget);
      expect(star(tester, Asset.btc).onPressed, isNotNull);
      expect(star(tester, Asset.usdt).onPressed, isNotNull);
    });

    testWidgets('a drag on the handle puts the second pin first, for the '
        'home too', (tester) async {
      await open(tester, ['Bitcoin', 'USDT']);
      final top = tester.getTopLeft(find.text('Bitcoin')).dy;

      final gesture = await tester.startGesture(
        tester.getCenter(handles().last),
      );
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(container.read(favoriteAssetsProvider), [Asset.usdt, Asset.btc]);
      expect(saved(), [Asset.usdt.name, Asset.btc.name]);
      expect(tester.getTopLeft(find.text('USDT').first).dy, top);
    });

    testWidgets('the dragged row stays inside the panel, however far the '
        'finger goes', (tester) async {
      await open(tester, ['Bitcoin', 'USDT']);
      final panel = tester.getRect(
        find.ancestor(
          of: find.byType(ReorderableListView),
          matching: find.byType(GlassPanel),
        ),
      );
      // The card of the dragged row: the only opaque glass on the screen.
      final card = find.byWidgetPredicate((w) => w is LiquidGlass && w.opaque);
      // The card grows by 2% while lifted, about a point at each edge.
      const slack = 2.0;

      final gesture = await tester.startGesture(
        tester.getCenter(handles().last),
      );
      await tester.pump();
      // Far above the panel, over the header and the title.
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -60));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(card).top, greaterThanOrEqualTo(panel.top - slack));

      // Far below it, over the other assets.
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.getRect(card).bottom,
        lessThanOrEqualTo(panel.bottom + slack),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('with one pin, no handle, and its star is off with the '
        'reason', (tester) async {
      await open(tester, ['Bitcoin']);

      expect(handles(), findsNothing);
      expect(find.text(t.wallet_all_assets_hint_one), findsOneWidget);
      final locked = star(tester, Asset.btc);
      expect(locked.onPressed, isNull);
      expect(locked.tooltip, t.wallet_all_assets_keep_one);

      await tester.tap(find.byTooltip(t.wallet_all_assets_keep_one));
      await tester.pumpAndSettle();
      expect(container.read(favoriteAssetsProvider), [Asset.btc]);
    });

    testWidgets('unpinning one of two leaves one, and its star turns off', (
      tester,
    ) async {
      await open(tester, ['Bitcoin', 'USDT']);

      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is PinStarButton && w.asset == Asset.usdt,
          ),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(favoriteAssetsProvider), [Asset.btc]);
      expect(handles(), findsNothing);
      expect(star(tester, Asset.btc).onPressed, isNull);
    });

    for (final brightness in Brightness.values) {
      testWidgets('two pins fit a 320 pt screen at 200% text in the '
          '${brightness.name} theme', (tester) async {
        await open(
          tester,
          ['Bitcoin', 'USDT'],
          brightness: brightness,
          size: const Size(320, 640),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(handles(), findsNWidgets(2));
      });
    }
  });
}

SharedPreferences? _prefs;
