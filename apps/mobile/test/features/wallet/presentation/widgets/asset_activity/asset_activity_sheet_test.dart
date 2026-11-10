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
    expect(top('0 sat'), lessThan(top('RECEBIDO TOTAL')));
    expect(top('RECEBIDO TOTAL'), lessThan(top('Volume movimentado')));
    expect(top('Volume movimentado'), lessThan(top('Primeira movimentação')));
    expect(top('Primeira movimentação'), lessThan(top('Última movimentação')));

    // Summary: received, sent, and the number of transactions.
    expect(find.text('ENVIADO TOTAL'), findsOneWidget);
    expect(find.text('TRANSAÇÕES'), findsOneWidget);
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
    expect(find.text('RECEBIDO TOTAL'), findsOneWidget);
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
    expect(find.text('RECEBIDO TOTAL'), findsOneWidget);
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
}
