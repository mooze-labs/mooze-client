import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/lbtc_insufficient_funds_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  testWidgets('the dialog offers the swap and a receive on Liquid, with '
      'no Lightning', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                LbtcInsufficientFundsDialog.show(context, asset: Asset.usdt),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(t.wallet_send_lbtc_insufficient_title), findsOneWidget);
    expect(find.text('L-BTC insuficiente'), findsOneWidget);
    expect(find.text(t.wallet_send_lbtc_insufficient_receive), findsOneWidget);
    expect(find.textContaining('Lightning'), findsNothing);
    expect(find.textContaining('Bitcoin L2'), findsNothing);
  });
}
