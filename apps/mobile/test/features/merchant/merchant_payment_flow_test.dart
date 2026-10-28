import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/merchant_payment_method.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_link_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_payment_method_screen.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

const _url = 'https://pay.mooze.app/pay/tok_abc123';
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

/// The app theme, the Portuguese texts and a button that runs [open].
Widget _host(
  Future<void> Function(BuildContext context) open, {
  bool cpfRequired = true,
}) {
  return ProviderScope(
    overrides: [pixCpfRequiredProvider.overrideWithValue(cpfRequired)],
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
      expect(find.text('Você recebe em BTC L2'), findsOneWidget);
      expect(find.text('Na hora'), findsOneWidget);
      expect(find.text('Pede CPF'), findsOneWidget);
      expect(find.text('À distância'), findsOneWidget);
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
      // The reveal animation runs for two seconds, then removes itself.
      await tester.pumpAndSettle();
    }

    testWidgets('shows the link as a QR Code, the address and the actions', (
      tester,
    ) async {
      await openLink(tester, (_) {});

      expect(find.byType(PrettyQrView), findsOneWidget);
      expect(find.text(_url), findsOneWidget);
      expect(find.text('Endereço do link'), findsOneWidget);
      expect(find.textContaining('45,90'), findsOneWidget);
      expect(find.text('Você recebe em Depix'), findsOneWidget);
      expect(find.text('Uso único'), findsOneWidget);
      expect(find.text('Compartilhar link'), findsOneWidget);
      expect(find.text('Concluir venda'), findsOneWidget);
      // "Open in the browser" is below the link address.
      await tester.scrollUntilVisible(
        find.text('Abrir no navegador'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Abrir no navegador'), findsOneWidget);
    });

    testWidgets('"Concluir venda" ends the sale', (tester) async {
      bool? finished;
      await openLink(tester, (value) => finished = value);

      await tester.tap(find.text('Concluir venda'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });

    // A second visit to the same sale opens the link without the reveal.
    testWidgets('a visit without the reveal closes cleanly', (tester) async {
      bool? finished;
      await tester.pumpWidget(
        _host((context) async {
          finished = await MerchantPaymentLinkScreen.open(
            context,
            link: _link,
            request: _request,
            playReveal: false,
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _back(tester);
      await tester.pumpAndSettle();

      expect(finished, isFalse);
      expect(tester.takeException(), isNull);
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
