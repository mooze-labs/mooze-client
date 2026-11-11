import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/import_wallet/import_wallet_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/import_wallet/providers/seed_phrase_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/import_wallet/seed_qr_scan_screen.dart';
import 'package:mooze_mobile/features/setup/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/security/secure_screen.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';

import 'setup_test_app.dart';

/// Vector 4 of the SeedQR specification.
const _phrase =
    'forum undo fragile fade shy sign arrest garment culture tube off merit';
const _digits = '073318950739065415961602009907670428187212261116';

/// Vector 6, whose CompactSeedQR bytes hold a `\x00` and a `\n`.
const _compactPhrase =
    'approve fruit lens brass ring actual stool coin doll boss strong rate';
final _compact = Uint8List.fromList([
  0x0a, 0xcb, 0xba, 0x00, 0x8d, 0x9b, 0xa0, 0x05, //
  0xf5, 0x99, 0x6b, 0x40, 0xa3, 0x47, 0x5c, 0xd9,
]);

class _AnyState extends Fake implements GoRouterState {}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  Future<void> open(WidgetTester tester) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('first access')),
        ),
        GoRoute(
          path: '/setup/import-wallet',
          builder: (_, _) => const ImportWalletScreen(),
        ),
        GoRoute(
          path: '/setup/import-wallet/seed-qr',
          builder: (_, _) => const SeedQrScanScreen(
            debugPreview: ColoredBox(color: Colors.black),
          ),
        ),
      ],
    );
    await tester.pumpWidget(setupTestApp(router: router));
    router.push('/setup/import-wallet');
    await settle(tester);
  }

  SeedPhraseState phrase(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(Navigator).first),
  ).read(seedPhraseProvider);

  QrScannerView scanner(WidgetTester tester) =>
      tester.widget<QrScannerView>(find.byType(QrScannerView));

  Future<void> openScanner(WidgetTester tester) async {
    await tester.tap(find.text(t.setup_import_scan_seedqr));
    await settle(tester);
  }

  Future<void> scan(WidgetTester tester, Barcode barcode) async {
    scanner(tester).onBarcode!(barcode);
    await settle(tester);
  }

  testWidgets('the app opens the camera step behind the screen protection', (
    tester,
  ) async {
    final route = setupRoutes.whereType<GoRoute>().singleWhere(
      (route) => route.path == '/setup/import-wallet/seed-qr',
    );
    late Widget page;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          page = route.builder!(context, _AnyState());
          return const SizedBox();
        },
      ),
    );

    expect(
      page,
      isA<SecureScreen>().having(
        (screen) => screen.child,
        'child',
        isA<SeedQrScanScreen>(),
      ),
    );
  });

  testWidgets('the import offers to scan a SeedQR, which opens the camera', (
    tester,
  ) async {
    await open(tester);

    await openScanner(tester);

    expect(find.byType(SeedQrScanScreen), findsOneWidget);
    expect(find.text(t.seedqr_scan_detail), findsOneWidget);
  });

  testWidgets('a Standard SeedQR fills the phrase, and the import checks it '
      'as typed words before it imports', (tester) async {
    await open(tester);
    await openScanner(tester);

    await scan(tester, const Barcode(rawValue: _digits));

    expect(find.byType(SeedQrScanScreen), findsNothing);
    expect(phrase(tester).fullMnemonic, _phrase);
    expect(phrase(tester).isValid, isTrue);
    expect(find.text('Frase válida! Pronta para importar.'), findsOne);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled,
      isTrue,
    );
    expect(find.text(t.setup_import_scan_seedqr), findsNothing);
  });

  testWidgets('a CompactSeedQR fills the phrase from its bytes, whose \\x00 '
      'and \\n a text reader would break', (tester) async {
    await open(tester);
    await openScanner(tester);

    await scan(tester, Barcode(rawBytes: _compact));

    expect(find.byType(SeedQrScanScreen), findsNothing);
    expect(phrase(tester).fullMnemonic, _compactPhrase);
    expect(phrase(tester).isValid, isTrue);
  });

  testWidgets('the backup QR of BlueWallet, with the phrase in text, fills the '
      'phrase', (tester) async {
    await open(tester);
    await openScanner(tester);

    await scan(tester, const Barcode(rawValue: _phrase));

    expect(find.byType(SeedQrScanScreen), findsNothing);
    expect(phrase(tester).fullMnemonic, _phrase);
    expect(phrase(tester).isValid, isTrue);
  });

  testWidgets('a code that is not a SeedQR shows why, and the camera reads '
      'on', (tester) async {
    await open(tester);
    await openScanner(tester);

    await scan(tester, const Barcode(rawValue: 'https://mooze.app'));

    expect(find.text(t.seedqr_error_unsupported), findsOneWidget);
    expect(find.byType(SeedQrScanScreen), findsOneWidget);
    expect(phrase(tester).wordCount, 0);

    await scan(tester, const Barcode(rawValue: _digits));
    expect(find.byType(SeedQrScanScreen), findsNothing);
    expect(phrase(tester).fullMnemonic, _phrase);
    expect(find.text(t.seedqr_error_unsupported), findsNothing);
  });

  testWidgets('a SeedQR with a wrong checksum shows why and fills nothing', (
    tester,
  ) async {
    await open(tester);
    await openScanner(tester);

    await scan(tester, Barcode(rawValue: '0000' * 12));

    expect(find.text(t.seedqr_error_invalid), findsOneWidget);
    expect(find.byType(SeedQrScanScreen), findsOneWidget);
    expect(phrase(tester).wordCount, 0);
  });

  testWidgets('a refused code that stays in view does not repeat its error', (
    tester,
  ) async {
    await open(tester);
    await openScanner(tester);
    await scan(tester, const Barcode(rawValue: 'not a seed'));
    final shown = tester.element(find.byType(SnackBar));

    for (var i = 0; i < 4; i++) {
      scanner(tester).onBarcode!(const Barcode(rawValue: 'not a seed'));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await settle(tester);

    expect(tester.element(find.byType(SnackBar)), same(shown));
  });
}
