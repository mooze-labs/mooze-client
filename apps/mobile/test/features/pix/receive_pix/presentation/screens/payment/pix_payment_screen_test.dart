import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/pix_payment_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sample charge. Its code is not a real Pix code.
final _deposit = PixDeposit(
  depositId: 'deposit-1',
  pixKey: 'sample-pix-code-for-the-charge-screen-test',
  asset: Asset.depix,
  amountInCents: 5000,
  network: 'liquid',
  status: DepositStatus.pending,
  createdAt: DateTime.now(),
);

/// The widgets in the brand pink that cover the width of the screen.
List<Element> _pinkCovers(WidgetTester tester) {
  final context = tester.element(find.byType(ValidPixPaymentScreen));
  final pink = Theme.of(context).colorScheme.primary;
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  Color? colorOf(Widget widget) {
    if (widget is ColoredBox) return widget.color;
    if (widget is Container) {
      final decoration = widget.decoration;
      return decoration is BoxDecoration ? decoration.color : widget.color;
    }
    return null;
  }

  return [
    for (final element
        in find
            .byWidgetPredicate((widget) => colorOf(widget) == pink)
            .evaluate())
      if (element.size != null && element.size!.width >= width * 0.9) element,
  ];
}

void main() {
  testWidgets('the charge opens uncovered: no pink layer covers it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          assetQuoteProvider.overrideWith((ref, asset) async => right(some(5))),
          feeRateProvider.overrideWith((ref, amount) async => 0),
          discountedFeesDepositProvider.overrideWith(
            (ref, amount) async => amount,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: ValidPixPaymentScreen(deposit: _deposit),
        ),
      ),
    );
    await tester.pump();

    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(_pinkCovers(tester), isEmpty);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
