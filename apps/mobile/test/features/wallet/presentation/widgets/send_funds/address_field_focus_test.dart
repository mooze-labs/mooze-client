import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/address_field.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: const Scaffold(body: AddressField()),
        ),
      ),
    );
    await tester.pump();
  }

  bool fieldHasFocus(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

  // The send screen opens on the asset and the amount too. The keyboard
  // would cover them, and many users paste or scan the address. It opens
  // only when the user taps the field.
  testWidgets('the send screen opens with no focus and no keyboard', (
    tester,
  ) async {
    await open(tester);

    expect(fieldHasFocus(tester), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a tap on the field opens the keyboard', (tester) async {
    await open(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(fieldHasFocus(tester), isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
