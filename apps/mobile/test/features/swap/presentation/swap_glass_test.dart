import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_success_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/btc_lbtc_swap_warning_dialog.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/no_liquidity_dialog.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

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
      // The content fades and slides in until 1.4 s after the screen opens.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('shows the summary on a glass panel over the backdrop', (
      tester,
    ) async {
      await show(tester);

      expect(find.byType(AppBackdrop), findsOneWidget);
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

  group('BTC to LBTC warning dialog', () {
    testWidgets('is a glass alert that unlocks after 10 seconds', (
      tester,
    ) async {
      await _pump(
        tester,
        _app((context) => BtcLbtcSwapWarningDialog.show(context)),
      );
      await _open(tester);

      expect(find.byType(GlassAlertDialog), findsOneWidget);
      final button = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.pump(const Duration(seconds: 10));
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

      await tester.tap(button);
      await _finishRoute(tester);
      expect(find.byType(BtcLbtcSwapWarningDialog), findsNothing);
    });
  });
}
