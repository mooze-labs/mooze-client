import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_demo_badge.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_deposit_ownership_notice.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_operation_list.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_primary_action_cards.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_method_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_key_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders [child] with the app theme and the app translations.
Widget host(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: Builder(
      builder: (context) {
        final theme = brightness == Brightness.dark
            ? AppTheme.darkTheme(context)
            : AppTheme.lightTheme(context);
        return Theme(
          data: theme,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        );
      },
    ),
  );
}

/// Finds the [PixIcon] that draws [icon].
Finder _findPixIcon(PixIconData icon) => find.byWidgetPredicate(
  (widget) => widget is PixIcon && widget.icon == icon,
);

void main() {
  for (final brightness in Brightness.values) {
    group('Pix hub widgets in the ${brightness.name} theme', () {
      testWidgets('the demonstration badge is readable', (tester) async {
        await tester.pumpWidget(
          host(const PixDemoBadge(), brightness: brightness),
        );

        expect(find.text('Demonstração'), findsOneWidget);
      });

      testWidgets('a sent movement shows a negative amount', (tester) async {
        final transaction = PixTransaction(
          id: 'tx',
          kind: PixTransactionKind.sent,
          status: PixTransactionStatus.completed,
          counterpartyName: 'Ana Demonstracao',
          amountInCents: 8450,
          createdAt: DateTime(2026, 3, 14),
          method: PixSendMethod.key,
          reference: 'DEMO-123456',
        );

        await tester.pumpWidget(
          host(
            PixTransactionTile(transaction: transaction),
            brightness: brightness,
          ),
        );

        expect(find.text('Ana Demonstracao'), findsOneWidget);
        // A true minus sign, as in the wallet lists.
        expect(find.textContaining('− R\$'), findsOneWidget);
        expect(find.textContaining('14/03/2026'), findsOneWidget);
      });

      testWidgets('a failed movement shows its status', (tester) async {
        final transaction = PixTransaction(
          id: 'tx',
          kind: PixTransactionKind.received,
          status: PixTransactionStatus.failed,
          counterpartyName: 'Bruno Ficticio',
          amountInCents: 1000,
          createdAt: DateTime(2026, 3, 14),
          reference: 'DEMO-654321',
        );

        await tester.pumpWidget(
          host(
            PixTransactionTile(transaction: transaction),
            brightness: brightness,
          ),
        );

        expect(find.text('Falhou'), findsOneWidget);
      });

      testWidgets('a key row hides the key value', (tester) async {
        final key = PixKey(
          id: 'key',
          type: PixKeyType.cpf,
          value: '52998224725',
          createdAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          host(PixKeyTile(pixKey: key), brightness: brightness),
        );

        expect(find.text('***.982.247-**'), findsOneWidget);
        expect(find.text('52998224725'), findsNothing);
      });

      testWidgets('the summary card lists every entry', (tester) async {
        await tester.pumpWidget(
          host(
            const PixSummaryCard(
              entries: [
                PixSummaryEntry('Para', 'Ana Demonstracao'),
                PixSummaryEntry('Valor', r'R$ 84,50', highlight: true),
              ],
            ),
            brightness: brightness,
          ),
        );

        expect(find.text('Para'), findsOneWidget);
        expect(find.text(r'R$ 84,50'), findsOneWidget);
      });

      testWidgets('the amount field reports the value in cents', (
        tester,
      ) async {
        var reported = 0;

        await tester.pumpWidget(
          host(
            PixAmountField(
              autofocus: false,
              onChanged: (cents) => reported = cents,
            ),
            brightness: brightness,
          ),
        );

        await tester.enterText(find.byType(TextField), '8450');
        await tester.pump();

        expect(reported, 8450);
      });

      testWidgets('the header is transparent while the list is at the top', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            PixHubHeader(onScan: () {}, onInfo: () {}),
            brightness: brightness,
          ),
        );

        final decoration =
            tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration
                as BoxDecoration;

        expect(decoration.color, Colors.transparent);
        expect(decoration.border?.bottom.color, Colors.transparent);
        // The backdrop slice stays hidden at the top.
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );
      });

      testWidgets('the header paints the backdrop slice once scrolled', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            PixHubHeader(onScan: () {}, onInfo: () {}, isScrolled: true),
            brightness: brightness,
          ),
        );

        final decoration =
            tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration
                as BoxDecoration;

        // The header shows its slice of the screen backdrop, which is
        // opaque, so the content does not show through it.
        final slice = find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.byType(AppBackdrop),
        );
        expect(slice, findsOneWidget);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
        expect(decoration.border?.bottom.color, isNot(Colors.transparent));
      });

      testWidgets('the header actions report back', (tester) async {
        var scans = 0;
        var infos = 0;

        await tester.pumpWidget(
          host(
            PixHubHeader(onScan: () => scans++, onInfo: () => infos++),
            brightness: brightness,
          ),
        );

        await tester.tap(_findPixIcon(PixIcons.scan));
        await tester.tap(_findPixIcon(PixIcons.info));

        expect(scans, 1);
        expect(infos, 1);
      });

      testWidgets('the receive card shows its label and description', (
        tester,
      ) async {
        var taps = 0;

        await tester.pumpWidget(
          host(
            PixHighlightActionCard(
              icon: PixIcons.qrCode,
              label: 'Receber',
              description: 'Compartilhe sua chave ou gere um QR Code',
              onTap: () => taps++,
            ),
            brightness: brightness,
          ),
        );

        expect(find.text('Receber'), findsOneWidget);
        // A no-break space keeps the last two words on the same line.
        expect(
          find.text('Compartilhe sua chave ou gere um QR Code'),
          findsOneWidget,
        );

        await tester.tap(find.byType(PixHighlightActionCard));
        expect(taps, 1);
      });

      testWidgets('the compact cards sit side by side', (tester) async {
        await tester.pumpWidget(
          host(
            Row(
              children: [
                Expanded(
                  child: PixCompactActionCard(
                    icon: PixIcons.send,
                    label: 'Enviar',
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: PixCompactActionCard(
                    icon: PixIcons.deposit,
                    label: 'Depositar',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            brightness: brightness,
          ),
        );

        final send = tester.getRect(find.text('Enviar'));
        final deposit = tester.getRect(find.text('Depositar'));
        expect(send.top, deposit.top);
        expect(send.left, lessThan(deposit.left));
      });

      testWidgets('the operation list draws a divider between rows', (
        tester,
      ) async {
        var taps = 0;

        await tester.pumpWidget(
          host(
            PixOperationList(
              items: [
                PixOperationItem(
                  icon: PixIcons.key,
                  label: 'Pagar com chave Pix',
                  onTap: () => taps++,
                ),
                PixOperationItem(
                  icon: PixIcons.link,
                  label: 'Links de pagamento',
                  onTap: () {},
                ),
              ],
            ),
            brightness: brightness,
          ),
        );

        expect(find.byType(Divider), findsOneWidget);
        await tester.tap(find.text('Pagar com chave Pix'));
        expect(taps, 1);
      });

      testWidgets('the operation list divider starts at the labels', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            PixOperationList(
              items: [
                PixOperationItem(
                  icon: PixIcons.key,
                  label: 'Pagar com chave Pix',
                  onTap: () {},
                ),
                PixOperationItem(
                  icon: PixIcons.link,
                  label: 'Links de pagamento',
                  onTap: () {},
                ),
              ],
            ),
            brightness: brightness,
          ),
        );

        final list = tester.getTopLeft(find.byType(PixOperationList));
        final label = tester.getTopLeft(find.text('Links de pagamento'));
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.indent, label.dx - list.dx);
      });

      testWidgets('the deposit notice states the ownership rule', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(const PixDepositOwnershipNotice(), brightness: brightness),
        );

        expect(find.text('Importante'), findsOneWidget);
        expect(
          find.textContaining('conta bancária em seu próprio nome'),
          findsOneWidget,
        );
        expect(find.textContaining('terceiros'), findsOneWidget);
      });

      testWidgets('a method card exposes its title and description', (
        tester,
      ) async {
        var taps = 0;

        await tester.pumpWidget(
          host(
            PixMethodCard(
              icon: PixIcons.key,
              title: 'Chave Pix',
              description: 'CPF, CNPJ, telefone, e-mail ou chave aleatória',
              onTap: () => taps++,
            ),
            brightness: brightness,
          ),
        );

        expect(find.text('Chave Pix'), findsOneWidget);
        await tester.tap(find.byType(PixMethodCard));
        expect(taps, 1);
      });

      testWidgets('the selected key type row shows the check mark', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Column(
              children: [
                PixOptionRow(
                  icon: PixIcons.idCard,
                  label: 'CPF',
                  isSelected: true,
                  onTap: () {},
                ),
                PixOptionRow(
                  icon: PixIcons.company,
                  label: 'CNPJ',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
            brightness: brightness,
          ),
        );

        expect(find.text('CPF'), findsOneWidget);
        expect(find.text('CNPJ'), findsOneWidget);
        expect(_findPixIcon(PixIcons.check), findsOneWidget);
      });

      testWidgets('the amount field shows the validation message', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            PixAmountField(
              autofocus: false,
              errorText: 'Informe um valor maior que zero.',
              onChanged: (_) {},
            ),
            brightness: brightness,
          ),
        );

        expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
      });
    });
  }
}
