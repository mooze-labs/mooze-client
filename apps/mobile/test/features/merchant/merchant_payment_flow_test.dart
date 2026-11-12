import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/merchant_payment_method.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_link_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_method_screen.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/inline_copy_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

// The token is long enough for the address to show short.
const _url = 'https://pay.mooze.app/pay/tok_abc123def456ghi';
const _request = (amountInCents: 4590, asset: Asset.depix);

final _link = PixPaymentLink(
  id: 'link-1',
  url: _url,
  reference: '',
  amountInCents: 4590,
  status: PixPaymentLinkStatus.pending,
  createdAt: DateTime(2026, 10, 21),
  singleUse: true,
);

/// Taps the back button of the app bar. `pageBack` looks for the English
/// tooltip, and these tests run in Portuguese.
Future<void> _back(WidgetTester tester) => tester.tap(find.byType(BackButton));

/// The levels of an account at [level]: 0 is Bronze, 1 is Silver.
UserLevelsData _levels(int level) => UserLevelsData(
  spendingLevel: level,
  levelProgress: 0,
  allowedSpending: 500,
  dailySpending: 0,
  currentLevelMinLimit: 0,
  currentLevelMaxLimit: 500,
  absoluteMinLimit: 20,
  absoluteMaxLimit: 3000,
  remainingLimit: 5000,
);

/// The app theme, the Portuguese texts and a button that runs [open]. The
/// account is Silver unless [level] says otherwise.
Widget _host(
  Future<void> Function(BuildContext context) open, {
  bool cpfRequired = true,
  int level = 1,
}) {
  return ProviderScope(
    overrides: [
      pixCpfRequiredProvider.overrideWithValue(cpfRequired),
      levelsProvider.overrideWith((ref) async => _levels(level)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      builder: (context, child) =>
          Theme(data: AppTheme.darkTheme(context), child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('payment method screen', () {
    for (final (label, expected) in [
      ('QR Code Pix', MerchantPaymentMethod.pixQrCode),
      ('Link de pagamento', MerchantPaymentMethod.paymentLink),
    ]) {
      testWidgets('returns ${expected.name}', (tester) async {
        MerchantPaymentMethod? chosen;
        await tester.pumpWidget(
          _host((context) async {
            chosen = await MerchantPaymentMethodScreen.choose(
              context,
              amountInCents: 4590,
              asset: Asset.depix,
            );
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(chosen, expected);
        expect(find.text('Como o cliente vai pagar?'), findsNothing);
      });
    }

    testWidgets('shows the amount, the asset and the option facts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          (context) => MerchantPaymentMethodScreen.choose(
            context,
            amountInCents: 4590,
            asset: Asset.lbtc,
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Como o cliente vai pagar?'), findsOneWidget);
      expect(find.textContaining('45,90'), findsOneWidget);
      expect(find.text('Você recebe em L-BTC'), findsOneWidget);
      expect(find.text('Na hora'), findsOneWidget);
      expect(find.text('Pede CPF'), findsOneWidget);
      expect(find.text('À distância'), findsOneWidget);
    });

    // Payment links start at the Silver level. A Bronze merchant sees it on
    // the option, and a tap explains it instead of creating a link.
    testWidgets('a Bronze account sees that the link starts at Silver, and '
        'a tap explains it', (tester) async {
      final t = lookupAppLocalizations(const Locale('pt'));
      var returned = false;
      MerchantPaymentMethod? chosen;
      await tester.pumpWidget(
        _host((context) async {
          chosen = await MerchantPaymentMethodScreen.choose(
            context,
            amountInCents: 4590,
            asset: Asset.depix,
          );
          returned = true;
        }, level: 0),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(t.pix_hub_link_level_locked_tag), findsOneWidget);

      await tester.tap(find.text('Link de pagamento'));
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.text(t.pix_hub_link_level_locked_title), findsOneWidget);
      expect(find.text(t.pix_hub_link_level_locked_body), findsOneWidget);
      // The merchant opened it, so it shows that a drag closes it.
      expect(find.byType(GlassSheetHandle), findsOneWidget);

      await tester.tap(find.text(t.common_understood));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsNothing);
      expect(returned, isFalse);

      await tester.tap(find.text('QR Code Pix'));
      await tester.pumpAndSettle();
      expect(chosen, MerchantPaymentMethod.pixQrCode);
    });

    testWidgets('a Silver account sees no level tag', (tester) async {
      final t = lookupAppLocalizations(const Locale('pt'));
      await tester.pumpWidget(
        _host(
          (context) => MerchantPaymentMethodScreen.choose(
            context,
            amountInCents: 4590,
            asset: Asset.depix,
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(t.pix_hub_link_level_locked_tag), findsNothing);
    });

    testWidgets('does not promise a CPF step that is off', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => MerchantPaymentMethodScreen.choose(
            context,
            amountInCents: 4590,
            asset: Asset.depix,
          ),
          cpfRequired: false,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pede CPF'), findsNothing);
      expect(find.text('Na hora'), findsOneWidget);
    });

    testWidgets('going back returns no method', (tester) async {
      var returned = false;
      MerchantPaymentMethod? chosen = MerchantPaymentMethod.pixQrCode;
      await tester.pumpWidget(
        _host((context) async {
          chosen = await MerchantPaymentMethodScreen.choose(
            context,
            amountInCents: 4590,
            asset: Asset.depix,
          );
          returned = true;
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _back(tester);
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(chosen, isNull);
    });
  });

  group('payment link screen', () {
    // The screen must fit a phone with no scroll. The wide test font would
    // wrap every label, so this group lays out with the app font.
    setUpAll(() async {
      final loader = FontLoader(AppTextStyles.fontFamily);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(
          rootBundle.load(
            'assets/fonts/geist-font/Geist/ttf/Geist-$weight.ttf',
          ),
        );
      }
      await loader.load();
    });

    Future<void> openLink(
      WidgetTester tester,
      void Function(bool finished) onClosed,
    ) async {
      // A phone screen, so the lazy list builds the whole page.
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host((context) async {
          onClosed(
            await MerchantPaymentLinkScreen.open(
              context,
              link: _link,
              request: _request,
            ),
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens uncovered: no pink layer covers it', (tester) async {
      await tester.pumpWidget(
        _host((context) async {
          await MerchantPaymentLinkScreen.open(
            context,
            link: _link,
            request: _request,
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pump();

      final pink = Theme.of(
        tester.element(find.text('open')),
      ).colorScheme.primary;
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.byWidgetPredicate((w) => w is ColoredBox && w.color == pink),
          findsNothing,
        );
      }
      await tester.pumpAndSettle();
    });

    testWidgets('shows the link as a QR Code, the address and the actions', (
      tester,
    ) async {
      await openLink(tester, (_) {});

      expect(find.byType(PrettyQrView), findsOneWidget);
      expect(find.text('Endereço do link'), findsOneWidget);
      expect(find.textContaining('45,90'), findsOneWidget);
      expect(find.text('Você recebe em Depix'), findsOneWidget);
      expect(find.text('Uso único'), findsOneWidget);
      expect(find.text('Compartilhar link'), findsOneWidget);
      expect(find.text('Abrir no navegador'), findsOneWidget);
      expect(find.text('Concluir venda'), findsOneWidget);
    });

    // The address shows the ends of its token, as the link details in the
    // Pix hub show it. The whole address goes to the copy.
    testWidgets('the address shows short', (tester) async {
      await openLink(tester, (_) {});

      expect(find.text(shortLinkAddress(_url)), findsOneWidget);
      expect(find.text(_url), findsNothing);
    });

    // As in the link details of the Pix hub: one panel below the QR Code
    // holds the address with copy, the share, and the browser.
    testWidgets('one panel holds the address, the share and the browser', (
      tester,
    ) async {
      await openLink(tester, (_) {});

      Element panelOf(String text) => find
          .ancestor(of: find.text(text), matching: find.byType(GlassPanel))
          .evaluate()
          .first;
      final panel = panelOf('Endereço do link');
      for (final text in ['Compartilhar link', 'Abrir no navegador']) {
        expect(panelOf(text), same(panel), reason: text);
        expect(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(InCardActionButton),
          ),
          findsOneWidget,
          reason: text,
        );
      }
    });

    // The actions moved into the panel. The bottom keeps only the end of
    // the sale, outlined: it is not filled, so it does not look like the
    // next step of the payment.
    testWidgets('the bottom holds only "Concluir venda", outlined', (
      tester,
    ) async {
      await openLink(tester, (_) {});

      expect(find.byType(PrimaryButton), findsNothing);
      expect(
        find.ancestor(
          of: find.text('Concluir venda'),
          matching: find.byType(SecondaryButton),
        ),
        findsOneWidget,
      );
      // Full width: as wide as the panel above it.
      final button = tester.getRect(find.byType(SecondaryButton));
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Endereço do link'),
              matching: find.byType(GlassPanel),
            )
            .first,
      );
      expect(button.width, panel.width);
    });

    testWidgets('the QR Code, the address and the actions fit a phone above '
        'the bottom button, with no scroll', (tester) async {
      // The status bar and the home indicator of an iPhone 15.
      tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
      await openLink(tester, (_) {});

      for (final finder in [
        find.byType(PrettyQrView),
        find.text(shortLinkAddress(_url)),
        find.text('Compartilhar link'),
        find.text('Abrir no navegador'),
      ]) {
        expect(finder.hitTestable(), findsOneWidget);
      }
      final open = find.ancestor(
        of: find.text('Abrir no navegador'),
        matching: find.byType(InCardActionButton),
      );
      expect(
        tester.getRect(open).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(SecondaryButton)).top),
      );
    });

    testWidgets('the copy button of the address copies the whole link', (
      tester,
    ) async {
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
      await openLink(tester, (_) {});

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(DetailRow, 'Endereço do link'),
          matching: find.byType(InlineCopyButton),
        ),
      );
      await tester.pump();
      expect(copied, _url);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('"Compartilhar link" sends the amount and the link', (
      tester,
    ) async {
      final t = lookupAppLocalizations(const Locale('pt'));
      final shared = <String?>[];
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        shared.add((call.arguments as Map)['text'] as String?);
        return 'dev.fluttercommunity.plus/share/unavailable';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await openLink(tester, (_) {});

      await tester.tap(find.text('Compartilhar link'));
      await tester.pump();

      expect(shared, [
        t.merchant_payment_link_share_message(formatBrlCents(4590), _url),
      ]);
    });

    testWidgets('"Abrir no navegador" opens the link outside the app', (
      tester,
    ) async {
      final opened = <(Uri, LaunchMode)>[];
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          (context) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MerchantPaymentLinkScreen(
                link: _link,
                request: _request,
                debugLaunchUrl: (url, {mode = LaunchMode.platformDefault}) {
                  opened.add((url, mode));
                  return Future.value(true);
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir no navegador'));
      await tester.pump();

      expect(opened, [(Uri.parse(_url), LaunchMode.externalApplication)]);
    });

    testWidgets('"Concluir venda" ends the sale', (tester) async {
      bool? finished;
      await openLink(tester, (value) => finished = value);

      await tester.tap(find.text('Concluir venda'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });

    testWidgets('back returns to the charge screen', (tester) async {
      bool? finished;
      await openLink(tester, (value) => finished = value);

      await _back(tester);
      await tester.pumpAndSettle();

      expect(finished, isFalse);
    });
  });
}
