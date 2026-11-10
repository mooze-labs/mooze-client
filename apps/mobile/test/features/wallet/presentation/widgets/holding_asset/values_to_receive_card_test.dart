import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

Widget _app(Either<String, List<AssetToReceive>> values) => ProviderScope(
  overrides: [
    valuesToReceiveProvider.overrideWith((ref) async => values),
    totalValueToReceiveProvider.overrideWith((ref) async => 0),
    currencySymbolProvider.overrideWithValue(r'R$'),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    builder: (context, child) =>
        Theme(data: AppTheme.darkTheme(context), child: child!),
    home: const Scaffold(body: ValuesToReceiveCard()),
  ),
);

void main() {
  // The card shows nothing without values, so the pulse never ran. Leaving
  // the screen then disposed a pulse that did not exist yet: creating it
  // looked up the ticker mode of a deactivated element.
  for (final (name, values) in [
    ('nothing to receive', const Right<String, List<AssetToReceive>>([])),
    ('a load error', const Left<String, List<AssetToReceive>>('offline')),
  ]) {
    testWidgets('closes cleanly with $name', (tester) async {
      await tester.pumpWidget(_app(values));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('closes cleanly while it loads', (tester) async {
    await tester.pumpWidget(_app(const Right([])));

    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
  });
}
