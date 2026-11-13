import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_success_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/btc_lbtc_swap_warning_sheet.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/no_liquidity_dialog.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

const _txid =
    'f3a9c1d2e4b5a6978877665544332211aabbccddeeff00112233445566778899';

/// Renders a page with one button that runs [onOpen]. The app theme is on
/// the MaterialApp, as in main.dart, so routes get it too.
Widget _app(void Function(BuildContext context) onOpen) {
  return MediaQuery(
    data: const MediaQueryData(size: _phone),
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        theme: AppTheme.darkTheme(context),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => onOpen(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Size of an iPhone 15 screen in points.
const _phone = Size(393, 852);

/// Pumps [app] on a phone-size screen.
Future<void> _pump(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = _phone * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await _finishRoute(tester);
}

/// Runs a route transition to its end. A popped route leaves the tree one
/// frame after its animation ends. The success screen repeats a glow, so
/// `pumpAndSettle` would never return.
Future<void> _finishRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

void main() {
  // The success screen lays out its amounts in one row. With the wide test
  // font, the row overflows, so the tests load the app font.
  setUpAll(() async {
    final loader = FontLoader(AppTextStyles.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        rootBundle.load('assets/fonts/geist-font/Geist/ttf/Geist-$weight.ttf'),
      );
    }
    await loader.load();
  });

  group('Swap success screen', () {
    Future<void> show(WidgetTester tester) async {
      await _pump(
        tester,
        _app(
          (context) => SwapSuccessScreen.show(
            context,
            fromAsset: core.Asset.depix,
            toAsset: core.Asset.lbtc,
            amountSent: 500,
            amountReceived: 0.001135,
            txid: _txid,
          ),
        ),
      );
      await _open(tester);
      // The summary fades in as the coin comes to rest.
      await tester.pump(Motion.durationSwap);
    }

    testWidgets('shows the summary on a glass panel, on the black stage', (
      tester,
    ) async {
      await show(tester);

      final background = tester
          .widget<Scaffold>(find.byType(Scaffold).last)
          .backgroundColor!;
      expect(background.computeLuminance(), lessThan(0.01));
      expect(find.byType(GlassPanel), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('a tap on the transaction ID copies it', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await show(tester);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copied, _txid);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('the button goes back', (tester) async {
      await show(tester);

      await tester.tap(find.byType(PrimaryButton));
      await _finishRoute(tester);
      expect(find.byType(SwapSuccessScreen), findsNothing);
    });
  });

  group('No liquidity dialog', () {
    testWidgets('is a glass dialog and retry closes it', (tester) async {
      var retries = 0;
      await _pump(
        tester,
        _app(
          (context) =>
              NoLiquidityDialog.show(context, onRetry: () => retries++),
        ),
      );
      await _open(tester);

      expect(find.byType(GlassDialog), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await _finishRoute(tester);

      expect(retries, 1);
      expect(find.byType(NoLiquidityDialog), findsNothing);
    });
  });

  // The swap screen shows this notice on its own, the first time the user
  // picks BTC and L-BTC. It is a floating glass sheet, as the other
  // notices of the app, and only its button closes it.
  group('BTC to LBTC warning', () {
    final t = lookupAppLocalizations(const Locale('pt'));

    Future<void> show(WidgetTester tester) async {
      await _pump(
        tester,
        _app((context) => BtcLbtcSwapWarningSheet.show(context)),
      );
      await _open(tester);
    }

    PrimaryButton button(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton));

    testWidgets('opens as a floating glass sheet, not a dialog', (
      tester,
    ) async {
      await show(tester);

      expect(find.text(t.swap_btc_lbtc_warning_title), findsOneWidget);
      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(GlassAlertDialog), findsNothing);
    });

    testWidgets('it keeps every point of the warning', (tester) async {
      await show(tester);

      for (final text in [
        t.swap_btc_lbtc_warning_intro,
        t.swap_btc_lbtc_warning_provider,
        t.swap_btc_lbtc_warning_timing,
        t.swap_btc_lbtc_warning_fee,
        t.swap_btc_lbtc_warning_peg_out_return,
        t.swap_btc_lbtc_warning_funds_safe,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    // The user must read about refunds before the swap: a tap outside or a
    // drag down does not close the sheet.
    testWidgets('a tap outside or a drag down does not close it', (
      tester,
    ) async {
      await show(tester);
      // No handle: nothing hints at a drag that does not close it.
      expect(find.byType(GlassSheetHandle), findsNothing);

      await tester.tapAt(const Offset(20, 20));
      await _finishRoute(tester);
      expect(find.byType(GlassSheet), findsOneWidget);

      final top = tester.getRect(find.byType(GlassSheet)).topCenter;
      await tester.dragFrom(top + const Offset(0, 16), const Offset(0, 500));
      await _finishRoute(tester);
      expect(find.byType(GlassSheet), findsOneWidget);
    });

    testWidgets('the button unlocks after 10 seconds and closes the sheet', (
      tester,
    ) async {
      await _pump(
        tester,
        _app((context) => BtcLbtcSwapWarningSheet.show(context)),
      );
      await tester.tap(find.text('open'));
      // The countdown starts with the sheet. Its entrance takes less than
      // a second, so all 10 seconds are left once it is up.
      await tester.pump();
      await tester.pump(Motion.durationSlow);

      expect(button(tester).isEnabled, isFalse);
      expect(
        find.text(t.swap_btc_lbtc_warning_accept_button_counting(10)),
        findsOneWidget,
      );

      // One second short of the reading time, the button is still locked.
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(button(tester).isEnabled, isFalse);
      expect(
        find.text(t.swap_btc_lbtc_warning_accept_button_counting(1)),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 1));
      expect(button(tester).isEnabled, isTrue);
      expect(find.text(t.swap_btc_lbtc_warning_accept_button), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await _finishRoute(tester);
      expect(find.byType(GlassSheet), findsNothing);
    });

    // The text scrolls inside the sheet, and the button stays on screen.
    for (final dark in [true, false]) {
      testWidgets('it fits a small phone with large text '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        // The media query of the view, so the text scale applies.
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => Theme(
              data: dark
                  ? AppTheme.darkTheme(context)
                  : AppTheme.lightTheme(context),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => BtcLbtcSwapWarningSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await _open(tester);

        expect(tester.takeException(), isNull);
        final action = tester.getRect(find.byType(PrimaryButton));
        expect(action.top, greaterThanOrEqualTo(0));
        expect(action.bottom, lessThanOrEqualTo(568));
      });
    }
  });
}
