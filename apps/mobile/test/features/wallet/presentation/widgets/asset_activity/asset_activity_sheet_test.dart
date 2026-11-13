import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/test_app.dart';

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Balance visibility without storage access: the balance shows.
class _FakeVisibility extends StateNotifier<bool>
    implements VisibilityNotifier {
  _FakeVisibility({bool hidden = false}) : super(hidden);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Size of the test screen: a phone with a home indicator.
const _screen = Size(390, 844);

/// Bounds of the tappable origin, like a holding row.
const _originRect = Rect.fromLTWH(20, 200, 350, 72);

/// A BTC history with movements, in sats.
final _active = AssetActivitySummary(
  asset: Asset.btc,
  transactionCount: 12,
  totalReceived: BigInt.from(300000),
  totalSent: BigInt.from(100000),
  totalVolume: BigInt.from(400000),
  largestReceive: BigInt.from(200000),
  largestSend: BigInt.from(60000),
  firstActivity: DateTime(2025, 1, 5),
  lastActivity: DateTime(2026, 10, 30, 14, 5),
);

/// A screen with one origin that opens the activity sheet of BTC with
/// [summary]. [hidden] hides the balance.
Widget _launcher({
  AsyncValue<AssetActivitySummary>? summary,
  bool hidden = false,
}) => ProviderScope(
  overrides: [
    walletHoldingsProvider.overrideWithValue(const AsyncValue.loading()),
    assetActivityProvider.overrideWith(
      (ref, asset) => summary ?? AsyncValue.data(_active),
    ),
    currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
    isVisibleProvider.overrideWith((ref) => _FakeVisibility(hidden: hidden)),
    localeStringProvider.overrideWithValue('pt_BR'),
  ],
  child: wrapForTest(
    Scaffold(
      body: Stack(
        children: [
          Positioned.fromRect(
            rect: _originRect,
            child: GlassSheetOrigin(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showAssetActivitySheet(context, asset: Asset.btc),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// [_launcher] with the app theme and its font, light or [dark], on a
/// [screen] with [textScale].
Widget _appLauncher({required bool dark}) => ProviderScope(
  overrides: [
    walletHoldingsProvider.overrideWithValue(const AsyncValue.loading()),
    assetActivityProvider.overrideWith(
      (ref, asset) => AsyncValue.data(_active),
    ),
    currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
    isVisibleProvider.overrideWith((ref) => _FakeVisibility()),
    localeStringProvider.overrideWithValue('pt_BR'),
  ],
  child: MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => Theme(
      data: dark ? AppTheme.darkTheme(context) : AppTheme.lightTheme(context),
      child: child!,
    ),
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fromRect(
            rect: _originRect,
            child: GlassSheetOrigin(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showAssetActivitySheet(context, asset: Asset.btc),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// A widget inside the sheet.
Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(AssetActivitySheet), matching: finder);

/// The icon wells of [icon] with [tone].
Finder _wells(PixIconData icon, PixTone tone) => _inSheet(
  find.byWidgetPredicate(
    (w) => w is PixIconWell && w.icon == icon && w.tone == tone,
  ),
);

/// Bounds of the sheet glass. The panels of the content come after it.
Rect _glass(WidgetTester tester) =>
    tester.getRect(find.byType(LiquidGlass).first);

/// Opens the sheet and lets it settle.
Future<void> _open(WidgetTester tester, Widget launcher) async {
  _usePhoneScreen(tester);
  await tester.pumpWidget(launcher);
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void _usePhoneScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = _screen * 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the sheet grows out of the origin and shows the activity', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('open'));
    await tester.pump();

    // First frame: the glass starts on the bounds of the origin.
    final start = _glass(tester);
    expect(start.topLeft, offsetMoreOrLessEquals(_originRect.topLeft));
    expect(start.size.width, moreOrLessEquals(_originRect.width));
    expect(start.size.height, moreOrLessEquals(_originRect.height));

    await tester.pumpAndSettle();
    expect(find.byType(AssetActivitySheet), findsOneWidget);
    expect(find.text(Asset.btc.name), findsOneWidget);
    expect(find.text(Asset.btc.ticker), findsOneWidget);
    // The origin stays where it was.
    expect(tester.getRect(find.byType(GlassSheetOrigin)), _originRect);
  });

  testWidgets('the sections show in order: balance, summary, highlights, '
      'timeline', (tester) async {
    await _open(tester, _launcher());

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    // The holdings are loading, so the balance shows zero.
    expect(top('0 sat'), lessThan(top('Recebido total')));
    expect(top('Recebido total'), lessThan(top('Volume movimentado')));
    expect(top('Volume movimentado'), lessThan(top('Primeira movimentação')));
    expect(top('Primeira movimentação'), lessThan(top('Última movimentação')));

    // Summary: received, sent, and the number of transactions.
    expect(find.text('Enviado total'), findsOneWidget);
    expect(find.text('Transações'), findsOneWidget);
    expect(find.text('300.000'), findsOneWidget);
    expect(find.text('100.000'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // Highlights.
    expect(find.text('400.000 sats'), findsOneWidget);
    expect(find.text('200.000 sats'), findsOneWidget);
    expect(find.text('60.000 sats'), findsOneWidget);
    // Timeline.
    expect(find.text('05 jan. 2025'), findsOneWidget);
    expect(find.text('30 out. 2026, 14:05'), findsOneWidget);
  });

  testWidgets('a hidden balance masks the amounts but keeps the count', (
    tester,
  ) async {
    await _open(tester, _launcher(hidden: true));

    expect(find.text('300.000'), findsNothing);
    expect(find.text('400.000 sats'), findsNothing);
    expect(find.text('••••'), findsWidgets);
    expect(find.text('••••••'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('an asset without movements shows zeros and no dates', (
    tester,
  ) async {
    await _open(
      tester,
      _launcher(
        summary: AsyncValue.data(AssetActivitySummary.empty(Asset.btc)),
      ),
    );

    // The panels keep their place, so the sheet does not jump when a
    // first movement arrives.
    expect(find.text('Recebido total'), findsOneWidget);
    expect(find.text('Volume movimentado'), findsOneWidget);
    // Received, sent, and the count.
    expect(find.text('0'), findsNWidgets(3));
    // Balance, volume, largest receive, and largest send.
    expect(find.text('0 sat'), findsNWidgets(4));
    // The market price and the two timeline dates are unknown.
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('a loading history shows the empty values, without skeletons', (
    tester,
  ) async {
    await _open(tester, _launcher(summary: const AsyncValue.loading()));

    expect(find.byType(SkeletonShimmer), findsNothing);
    expect(find.text('Recebido total'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('300.000'), findsNothing);
  });

  testWidgets('the close button shrinks the sheet back into the origin', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();
    var last = _glass(tester);
    while (find.byType(AssetActivitySheet).evaluate().isNotEmpty) {
      last = _glass(tester);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      last.topLeft,
      offsetMoreOrLessEquals(_originRect.topLeft, epsilon: 2),
    );
    expect(last.height, moreOrLessEquals(_originRect.height, epsilon: 2));
    expect(find.byType(LiquidGlass), findsNothing);
  });

  // The panels are glass lenses on the sheet glass, as the deal card of
  // the swap sheet: one for the summary, one for the highlights, one for
  // the timeline, and the pill of the market price.
  testWidgets('the panels are glass lenses inside the sheet', (tester) async {
    await _open(tester, _launcher());

    expect(_inSheet(find.byType(GlassLens)), findsNWidgets(4));
    // The section titles name the panels.
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Resumo'), lessThan(top('Recebido total')));
    expect(top('Destaques'), lessThan(top('Volume movimentado')));
    expect(top('Movimentações'), lessThan(top('Primeira movimentação')));
  });

  // The icons are those of the app, in round wells, as in the Pix screens.
  // The shape tells the direction; the green well marks what came in.
  testWidgets('the icons are the app icons, by meaning', (tester) async {
    await _open(tester, _launcher());

    // Received in the summary and the largest receive.
    expect(_wells(PixIcons.receive, PixTone.positive), findsNWidgets(2));
    // Sent in the summary and the largest send.
    expect(_wells(PixIcons.send, PixTone.neutral), findsNWidgets(2));
    expect(_wells(PixIcons.history, PixTone.neutral), findsOneWidget);
    expect(_wells(PixIcons.exchange, PixTone.neutral), findsOneWidget);
    expect(_wells(PixIcons.calendar, PixTone.neutral), findsOneWidget);
    expect(_wells(PixIcons.clock, PixTone.neutral), findsOneWidget);
    expect(
      _inSheet(
        find.byWidgetPredicate(
          (w) => w is PixIcon && w.icon == PixIcons.trendingUp,
        ),
      ),
      findsOneWidget,
    );
    // No Material icon is left.
    expect(_inSheet(find.byType(Icon)), findsNothing);
  });

  // A screen reader reads a metric as one: its value and its label.
  testWidgets('a metric reads its value with its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, _launcher());

    expect(
      find.bySemanticsLabel(RegExp(r'300\.000\s+Recebido total')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'12\s+Transações')), findsOneWidget);
    semantics.dispose();
  });

  group('the layout', () {
    setUpAll(() async {
      final geist = FontLoader(AppTextStyles.fontFamily);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        geist.addFont(
          rootBundle.load(
            'assets/fonts/geist-font/Geist/ttf/Geist-$weight.ttf',
          ),
        );
      }
      await geist.load();
    });

    for (final dark in [true, false]) {
      testWidgets('it fits a small phone with large text '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(_appLauncher(dark: dark));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Recebido total'), findsOneWidget);
      });
    }
  });
}
