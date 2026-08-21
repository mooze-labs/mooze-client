import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/features/swap/presentation/widgets/swap_deal_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/themes/app_theme.dart';

/// Regression cover for the confirmation card flashing `0`.
///
/// A max/drain peg has no user-supplied send amount — the wallet resolves
/// `balance − fee` — so the sheet passes `null` until the quote lands. The
/// card used to render the send row with `isShimmer: false` hardcoded, so a
/// null amount fell through to a literal `'0'` and read as "you are sending
/// nothing" for as long as the quote took.
void main() {
  // `_AmountRow` reads `context.colors`, so the card needs the app's theme
  // extensions — a bare ThemeData is not enough.
  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder:
          (ctx) => Theme(
            data: AppTheme.darkTheme(ctx),
            child: Scaffold(body: child),
          ),
    ),
  );

  SwapDealCard card({
    int? sendAmountSats,
    int? receiveAmountSats,
    bool isLoadingSend = false,
    bool isLoadingReceive = false,
  }) => SwapDealCard(
    sendAsset: core.Asset.lbtc,
    sendAmountSats: sendAmountSats,
    receiveAsset: core.Asset.btc,
    receiveAmountSats: receiveAmountSats,
    isLoadingSend: isLoadingSend,
    isLoadingReceive: isLoadingReceive,
    sendLabel: 'You send',
    receiveLabel: 'You receive',
  );

  testWidgets('a null send amount never renders as 0', (tester) async {
    await tester.pumpWidget(
      host(card(sendAmountSats: null, receiveAmountSats: null)),
    );
    await tester.pump();

    expect(
      find.text('0'),
      findsNothing,
      reason: 'an unresolved amount must shimmer, not claim to be zero',
    );
  });

  testWidgets('an explicit loading flag shimmers the send row', (tester) async {
    // Guards the drain case where the seed amount is known but wrong: MAX
    // seeds the gross balance, yet the send is balance − fee.
    await tester.pumpWidget(
      host(card(sendAmountSats: 200000, isLoadingSend: true)),
    );
    await tester.pump();

    expect(find.textContaining('200'), findsNothing);
  });

  testWidgets('a resolved send amount is shown once the quote lands', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(card(sendAmountSats: 199974, receiveAmountSats: 199748)),
    );
    await tester.pump();

    // Formatting is locale-dependent; assert on the digits that must appear.
    expect(find.textContaining('199'), findsWidgets);
  });

  testWidgets('a genuine zero send amount is still rendered', (tester) async {
    // Zero passed explicitly is data, not absence — the card must not hide it.
    await tester.pumpWidget(
      host(card(sendAmountSats: 0, receiveAmountSats: 0)),
    );
    await tester.pump();

    expect(find.text('0'), findsWidgets);
  });

  testWidgets('existing call sites are unaffected by the new flag', (
    tester,
  ) async {
    // The asset-swap and history cards always have a send amount and never
    // pass the flag; they must keep rendering exactly as before.
    await tester.pumpWidget(
      host(card(sendAmountSats: 50000, receiveAmountSats: 49900)),
    );
    await tester.pump();

    expect(find.textContaining('50'), findsWidgets);
    expect(find.textContaining('49'), findsWidgets);
  });
}
