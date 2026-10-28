import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Renders [home] with the app theme on the MaterialApp, as in main.dart.
Widget _app(Widget home, {Brightness brightness = Brightness.dark}) {
  // The media query comes from the test view, so the reduce-motion test
  // setting reaches the widgets. AppTheme needs it above the MaterialApp.
  return Builder(
    builder: (outer) => MediaQuery.fromView(
      view: View.of(outer),
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
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme(context)
              : AppTheme.lightTheme(context),
          home: home,
        ),
      ),
    ),
  );
}

Widget _page(Widget child, {Brightness brightness = Brightness.dark}) => _app(
  Scaffold(body: Center(child: child)),
  brightness: brightness,
);

void main() {
  group('PixIcons', () {
    test('every icon points to an SVG asset', () {
      final source = File(
        'lib/features/pix/shared/presentation/widgets/pix_icons.dart',
      ).readAsStringSync();
      final files = RegExp(
        r"\$_dir/([a-z_]+\.svg)",
      ).allMatches(source).map((m) => m.group(1)!).toList();

      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          File('assets/icons/pix/$file').existsSync(),
          isTrue,
          reason: file,
        );
      }
    });

    testWidgets('an icon takes its size and color from the icon theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          const IconTheme(
            data: IconThemeData(size: 30, color: Colors.teal),
            child: PixIcon(PixIcons.copy),
          ),
        ),
      );

      expect(tester.getSize(find.byType(PixIcon)), const Size(30, 30));
    });

    testWidgets('screen readers skip an icon without a label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixIcon(PixIcons.copy),
              PixIcon(PixIcons.share, semanticLabel: 'Compartilhar'),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('Compartilhar'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('PixIconWell', () {
    testWidgets('a neutral well is a glass lens', (tester) async {
      await tester.pumpWidget(_page(const PixIconWell(icon: PixIcons.key)));

      final context = tester.element(find.byType(PixIconWell));
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(PixIconWell),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, GlassStyle.of(context).lensFill);
      expect(
        tester.widget<PixIcon>(find.byType(PixIcon)).color,
        pixToneColor(context, PixTone.neutral),
      );
    });

    testWidgets('a status tone colors the icon', (tester) async {
      await tester.pumpWidget(
        _page(const PixIconWell(icon: PixIcons.check, tone: PixTone.positive)),
      );

      final context = tester.element(find.byType(PixIconWell));
      expect(
        tester.widget<PixIcon>(find.byType(PixIcon)).color,
        pixToneColor(context, PixTone.positive),
      );
    });
  });

  group('PixStatusView', () {
    testWidgets('each state has its own emblem shape', (tester) async {
      await tester.pumpWidget(
        _page(const PixStatusView(kind: PixStatusKind.processing, title: 'A')),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
        _page(const PixStatusView(kind: PixStatusKind.failure, title: 'B')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is PixIcon && w.icon == PixIcons.close),
        findsOneWidget,
      );
    });

    testWidgets('the title is a live region, so a new state is announced', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          const PixStatusView(
            kind: PixStatusKind.success,
            title: 'Pix entregue',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Pix entregue')),
        matchesSemantics(
          label: 'Pix entregue',
          isLiveRegion: true,
          isHeader: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('reduced motion shows a still spinner', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(
        _page(const PixStatusView(kind: PixStatusKind.processing, title: 'A')),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, isNotNull);
    });
  });

  group('PixCopyField', () {
    late List<String> clipboard;

    setUp(() => clipboard = []);

    void mockClipboard(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
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
    }

    testWidgets('a tap copies the value and confirms it for two seconds', (
      tester,
    ) async {
      mockClipboard(tester);
      var copies = 0;
      await tester.pumpWidget(
        _page(
          SizedBox(
            width: 360,
            child: PixCopyField(
              label: 'Pix Copia e Cola',
              value: '000201',
              onCopied: () => copies++,
            ),
          ),
        ),
      );
      expect(find.text('Copiar'), findsOneWidget);

      await tester.tap(find.byType(PixCopyField));
      await tester.pumpAndSettle();
      expect(clipboard, ['000201']);
      expect(copies, 1);
      expect(find.text('Copiado!'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is PixIcon && w.icon == PixIcons.check),
        findsOneWidget,
      );

      await tester.pump(PixCopyField.copiedDuration);
      await tester.pumpAndSettle();
      expect(find.text('Copiar'), findsOneWidget);
    });

    testWidgets('screen readers get the label, the value, and the action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          const SizedBox(
            width: 360,
            child: PixCopyField(label: 'ID', value: 'abc'),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PixCopyField)),
        matchesSemantics(
          label: 'ID',
          value: 'abc',
          hint: 'Copiar',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('PixQrPanel', () {
    testWidgets('draws the code on a white tile with a label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(const PixQrPanel(data: '000201', semanticLabel: 'QR Code Pix')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrettyQrView), findsOneWidget);
      expect(find.bySemanticsLabel('QR Code Pix'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('reduced motion shows the code at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_page(const PixQrPanel(data: '000201')));

      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(PixQrPanel),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('PixScreenScaffold', () {
    Widget scaffold() => PixScreenScaffold(
      appBarTitle: 'Enviar Pix',
      title: 'Quanto você quer enviar?',
      bottomAction: FilledButton(onPressed: () {}, child: const Text('OK')),
      children: const [Text('content')],
    );

    for (final brightness in Brightness.values) {
      testWidgets('uses the shared backdrop in the ${brightness.name} theme', (
        tester,
      ) async {
        await tester.pumpWidget(_app(scaffold(), brightness: brightness));
        await tester.pumpAndSettle();

        expect(find.byType(BackdropAppBar), findsOneWidget);
        expect(find.text('Enviar Pix'), findsOneWidget);
        expect(find.text('content'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the title is a header for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(scaffold()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Quanto você quer enviar?')),
        matchesSemantics(label: 'Quanto você quer enviar?', isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('reduced motion shows the content at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_app(scaffold()));

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('content'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('PixSummaryCard', () {
    testWidgets('values end on the right edge of the panel', (tester) async {
      await tester.pumpWidget(
        _page(
          const SizedBox(
            width: 360,
            child: PixSummaryCard(
              entries: [
                PixSummaryEntry('Valor', r'R$ 1.250,90', highlight: true),
                PixSummaryEntry('Taxa', r'R$ 2,00'),
              ],
            ),
          ),
        ),
      );

      final panel = tester.getRect(find.byType(GlassPanel));
      // 16 pt of panel padding on each side.
      expect(
        tester.getTopRight(find.text(r'R$ 2,00')).dx,
        closeTo(panel.right - 16, 0.5),
      );
      expect(
        tester.getTopRight(find.text(r'R$ 1.250,90')).dx,
        closeTo(panel.right - 16, 0.5),
      );
    });

    testWidgets('dividers use the panel hairline', (tester) async {
      await tester.pumpWidget(
        _page(
          const SizedBox(
            width: 360,
            child: PixSummaryCard(
              entries: [PixSummaryEntry('A', '1'), PixSummaryEntry('B', '2')],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Divider));
      expect(
        tester.widget<Divider>(find.byType(Divider)).color,
        AppSurfaces.hairline(context),
      );
    });
  });

  group('PixAmountField', () {
    testWidgets('reports cents and shows an error with an icon', (
      tester,
    ) async {
      int? cents;
      await tester.pumpWidget(
        _page(
          SizedBox(
            width: 360,
            child: PixAmountField(
              autofocus: false,
              onChanged: (value) => cents = value,
              errorText: 'Saldo insuficiente',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1250');
      expect(cents, 1250);
      expect(find.text('Saldo insuficiente'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is PixIcon && w.icon == PixIcons.error),
        findsOneWidget,
      );
    });
  });

  group('Large text on a narrow screen', () {
    void narrowLargeText(WidgetTester tester) {
      tester.view.physicalSize = const Size(320 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('a history row with a large amount does not overflow', (
      tester,
    ) async {
      narrowLargeText(tester);
      await tester.pumpWidget(
        _page(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PixTransactionTile(
              transaction: PixTransaction(
                id: '1',
                kind: PixTransactionKind.sent,
                status: PixTransactionStatus.pending,
                counterpartyName: 'Maria da Silva Pereira',
                amountInCents: 123456789,
                createdAt: DateTime(2026, 3, 14, 9, 30),
                reference: 'ref',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a summary label goes above its value', (tester) async {
      narrowLargeText(tester);
      await tester.pumpWidget(
        _page(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: PixSummaryCard(
              entries: [PixSummaryEntry('Por transação', r'R$ 5.000,00')],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text('Por transação'));
      final value = tester.getRect(find.text(r'R$ 5.000,00'));
      expect(value.top, greaterThanOrEqualTo(label.bottom));
    });
  });

  testWidgets('a summary label gets all the width the value leaves', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(
        const SizedBox(
          width: 353,
          child: PixSummaryCard(
            entries: [PixSummaryEntry('O destinatário recebe', r'R$ 10,00')],
          ),
        ),
      ),
    );

    // 353 pt minus 16 pt of panel padding on each side and the 16 pt gap.
    final value = tester.getSize(find.text(r'R$ 10,00')).width;
    final label = tester.renderObject<RenderParagraph>(
      find.text('O destinatário recebe'),
    );
    expect(label.constraints.maxWidth, closeTo(353 - 32 - 16 - value, 0.5));
  });
}
