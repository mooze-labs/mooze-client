import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/view_mnemonic.dart';
import 'package:mooze_mobile/features/setup/domain/seed_qr.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/display_seeds.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_display.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'setup_test_app.dart';

const _mnemonic =
    'abacate banana caju damasco figo goiaba jaca kiwi limão manga nêspera '
    'uva';

/// Vector 4 of the SeedQR specification, a valid BIP39 phrase.
const _bip39 =
    'forum undo fragile fade shy sign arrest garment culture tube off merit';

const _qrSubtitle =
    'Escaneie com o app da carteira de destino para importar sua frase.';

const _qrWarning =
    'Quem tiver este código tem acesso aos seus fundos. Não compartilhe nem '
    'tire foto.';

void main() {
  late OpenedRoutes opened;

  setUp(() => opened = OpenedRoutes());

  Future<void> open(
    WidgetTester tester,
    String path, {
    double textScale = 1,
    String mnemonic = _mnemonic,
  }) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/setup/create-wallet/display-seeds',
          builder: (_, _) => DisplaySeedsScreen(mnemonic: mnemonic),
        ),
        GoRoute(
          path: '/settings/seed',
          builder: (_, _) => ViewMnemonicScreen(mnemonic: mnemonic),
        ),
        opened.stub('/setup/create-wallet/confirm-seeds'),
      ],
    );
    await tester.pumpWidget(setupTestApp(router: router, textScale: textScale));
    await settle(tester);
  }

  Future<void> reveal(WidgetTester tester) async {
    await tester.tap(find.text('Toque para revelar'));
    await settle(tester);
  }

  void expectWordsOnGlass([String mnemonic = _mnemonic]) {
    final grid = find.descendant(
      of: find.byType(GlassPanel),
      matching: find.byType(MnemonicGridDisplay),
    );
    expect(grid, findsOneWidget);
    final fades = find.ancestor(
      of: grid,
      matching: find.byType(FadeTransition),
    );
    for (final fade in fades.evaluate()) {
      expect((fade.widget as FadeTransition).opacity.value, 1);
    }
    for (final word in mnemonic.split(' ')) {
      expect(
        find.descendant(
          of: grid,
          matching: find.textContaining(word, findRichText: true),
        ),
        findsOneWidget,
      );
    }
  }

  void expectNoWord() {
    for (final word in _mnemonic.split(' ')) {
      expect(find.textContaining(word, findRichText: true), findsNothing);
    }
  }

  for (final (name, path) in [
    ('the new phrase', '/setup/create-wallet/display-seeds'),
    ('the phrase in the settings', '/settings/seed'),
  ]) {
    group(name, () {
      testWidgets('hides the words under glass until the user reveals them', (
        tester,
      ) async {
        await open(tester, path);

        expect(find.byType(AppBackdrop), findsWidgets);
        expectNoWord();

        await reveal(tester);

        expectWordsOnGlass();
        expect(find.text('Toque para revelar'), findsNothing);
      });

      testWidgets('keeps the words from screen readers while hidden', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await open(tester, path);

        for (final word in _mnemonic.split(' ')) {
          expect(find.bySemanticsLabel(RegExp(word)), findsNothing);
        }
        expect(find.bySemanticsLabel('Toque para revelar'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('a tap on the words blurs them again', (tester) async {
        await open(tester, path);
        await reveal(tester);

        await tester.tap(find.byType(MnemonicGridDisplay));
        await settle(tester);

        expectNoWord();
        expect(find.text('Toque para revelar'), findsOneWidget);
      });

      testWidgets('hides the words when the app leaves the foreground', (
        tester,
      ) async {
        await open(tester, path);
        await reveal(tester);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expectNoWord();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expectNoWord();
      });

      testWidgets('fits a phone at 200% text', (tester) async {
        await open(tester, path, textScale: 2);
        await reveal(tester);

        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the new phrase goes on to its confirmation', (tester) async {
    await open(tester, '/setup/create-wallet/display-seeds');

    await tester.tap(find.text('Confirmar frase'));
    await settle(tester);

    expect(opened.last, '/setup/create-wallet/confirm-seeds');
    expect(opened.extras.last, _mnemonic);
  });

  testWidgets('the new phrase has no QR code', (tester) async {
    await open(tester, '/setup/create-wallet/display-seeds');

    expect(find.text('QR code'), findsNothing);
    expect(find.byType(PixQrPanel), findsNothing);
  });

  testWidgets('the settings copy the phrase, blurred or not', (tester) async {
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
    await open(tester, '/settings/seed');

    await tester.tap(find.text('Copiar seed'));
    await settle(tester);
    expect(copied, _mnemonic);
    expect(find.text('Copiado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text('Copiar seed'), findsOneWidget);
  });

  testWidgets('the settings show the phrase as a QR code that the import '
      'reads back', (tester) async {
    await open(tester, '/settings/seed', mnemonic: _bip39);

    await tester.tap(find.text('QR code'));
    await settle(tester);

    expect(find.byType(PixQrPanel), findsNothing);
    final drawnCodes = [
      for (final code
          in find
              .byWidgetPredicate(
                (w) => w.runtimeType.toString() == 'PrettyQrDataView',
              )
              .evaluate())
        (code.widget as dynamic).data as String,
    ];
    expect(drawnCodes, isNotEmpty);
    expect(drawnCodes, isNot(contains(_bip39)));
    expect(
      find.textContaining('QR code de Recuperação', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(_qrSubtitle), findsOneWidget);
    expect(find.text(_qrWarning), findsOneWidget);

    await reveal(tester);

    final phraseQr = find.byWidgetPredicate(
      (w) => w is PixQrPanel && w.data == _bip39,
    );
    expect(phraseQr, findsOneWidget);
    expect(
      find.ancestor(of: phraseQr, matching: find.byType(GlassPanel)),
      findsNothing,
    );
    final qr = tester.widget<PixQrPanel>(phraseQr);
    expect(SeedQr.decode(text: qr.data), right(_bip39));

    await tester.tap(phraseQr);
    await settle(tester);
    expect(phraseQr, findsNothing);

    await reveal(tester);
    await tester.tap(find.text('Palavras'));
    await settle(tester);
    expectWordsOnGlass(_bip39);
    expect(
      find.textContaining('Palavras de Recuperação', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(_qrWarning), findsNothing);
  });

  testWidgets('the QR code of the phrase fits a phone at 200% text', (
    tester,
  ) async {
    await open(tester, '/settings/seed', textScale: 2);

    await tester.tap(find.text('QR code'));
    await settle(tester);
    await reveal(tester);

    expect(tester.takeException(), isNull);
  });
}
