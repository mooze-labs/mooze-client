import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/lbtc_disclaimer_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// Opens the sheet from a button. The result of the sheet goes to
  /// [results].
  Future<void> open(WidgetTester tester, List<bool?> results) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  results.add(await LbtcDisclaimerSheet.show(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  PrimaryButton button(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  Future<void> waitCountdown(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('opens as a floating glass sheet, not a dialog', (tester) async {
    await open(tester, []);

    expect(find.text(t.wallet_send_lbtc_disclaimer_title), findsOneWidget);
    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.byType(GlassDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('a tap outside or a drag down does not close it', (tester) async {
    await open(tester, []);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsOneWidget);

    await tester.drag(
      find.text(t.wallet_send_lbtc_disclaimer_title),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsOneWidget);
  });

  testWidgets('the button unlocks after the countdown and closes the sheet '
      'with false', (tester) async {
    final results = <bool?>[];
    await open(tester, results);

    expect(button(tester).isEnabled, isFalse);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsOneWidget);

    await waitCountdown(tester);
    expect(button(tester).isEnabled, isTrue);
    expect(find.text(t.common_understood), findsOneWidget);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsNothing);
    expect(results, [false]);
  });

  testWidgets('the SWAP link closes the sheet with true', (tester) async {
    final results = <bool?>[];
    await open(tester, results);

    TapGestureRecognizer? swap;
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span is TextSpan && span.text == 'SWAP') {
          swap = span.recognizer as TapGestureRecognizer?;
        }
        return swap == null;
      });
    }
    swap!.onTap!();
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
    expect(results, [true]);
  });
}
