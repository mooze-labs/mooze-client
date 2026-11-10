import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_scan_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../check_digit_core_sync_helpers.dart';
import '../pix_send_fakes.dart';

const _email = 'ana@exemplo.com.br';

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  final t = lookupAppLocalizations(const Locale('pt'));
  late PixSendController controller;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = PixSendController(
      repository: FakeWithdrawalRepository(),
      wallet: FakeWithdrawalWallet(),
      records: PixWithdrawalRecordStore(await SharedPreferences.getInstance()),
      schedule: (_, _) => FakeTimer(),
    );
  });

  /// The hub, with the scan step pushed on top of it.
  Future<void> openScan(
    WidgetTester tester, {
    MobileScannerController? camera,
  }) async {
    router = GoRouter(
      initialLocation: '/pix',
      routes: [
        GoRoute(
          path: '/pix',
          builder: (_, _) => const Scaffold(body: Text('hub')),
        ),
        GoRoute(
          path: '/pix/send/scan',
          builder: (_, _) => PixSendScanScreen(
            debugPreview: const ColoredBox(color: Colors.black),
            debugController: camera,
          ),
        ),
        GoRoute(
          path: '/pix/send/amount',
          builder: (_, _) => const Scaffold(body: Text('amount')),
        ),
        GoRoute(
          path: '/pix/send/code',
          builder: (_, _) => const Scaffold(body: Text('copy and paste')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pixSendControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(
          routerConfig: router,
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
        ),
      ),
    );
    router.push('/pix/send/scan');
    await tester.pumpAndSettle();
  }

  QrScannerView scanner(WidgetTester tester) => tester.widget<QrScannerView>(
    find.byType(QrScannerView, skipOffstage: false),
  );

  /// Reports [code] as if the camera read it.
  Future<void> scan(WidgetTester tester, String code) async {
    scanner(tester).onCode(code);
    await tester.pumpAndSettle();
  }

  testWidgets('has the design of the wallet scan step', (tester) async {
    await openScan(tester);

    expect(find.text(t.pix_hub_action_pay_qr), findsOneWidget);
    expect(find.text(t.qr_scanner_position_hint), findsOneWidget);
    expect(find.text(t.pix_hub_send_method_qr_description), findsOneWidget);
    expect(find.text(t.qr_scanner_searching), findsOneWidget);
    expect(find.text(t.qr_scanner_flash_label), findsOneWidget);
  });

  testWidgets('a scanned code opens the amount step once', (tester) async {
    await openScan(tester);
    final code = PixBrCodeParser.build(
      pixKey: _email,
      merchantName: 'Padaria',
      merchantCity: 'Rio',
      amountInCents: 8450,
    );

    // The camera reports the code in view again before the step opens.
    scanner(tester).onCode(code);
    await scan(tester, code);

    final amountSteps = find.text('amount', skipOffstage: false);
    expect(amountSteps, findsOneWidget);
    expect(controller.state.draft?.pixKey, _email);
    // The code stays in handling while the amount step is open.
    expect(scanner(tester).found, isTrue);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text(t.qr_scanner_searching), findsOneWidget);
    expect(scanner(tester).found, isFalse);

    // Back on the camera, the next code starts a flow again.
    await scan(tester, code);
    expect(amountSteps, findsOneWidget);
  });

  testWidgets('an invalid code shows its error and scans again', (
    tester,
  ) async {
    await openScan(tester);
    const code = 'not a pix code';

    await scan(tester, code);

    expect(
      find.text(pixBrCodeErrorMessage(t, PixBrCodeParser.parse(code).error!)),
      findsOneWidget,
    );
    expect(find.text('amount'), findsNothing);
    expect(scanner(tester).found, isFalse);
  });

  testWidgets('a code without a Pix key is refused', (tester) async {
    await openScan(tester);
    String field(String id, String value) =>
        '$id${value.length.toString().padLeft(2, '0')}$value';
    final account =
        field('00', 'BR.GOV.BCB.PIX') + field('25', 'pix.exemplo.com/qr/1');
    final body =
        '${field('00', '01')}${field('26', account)}${field('52', '0000')}'
        '${field('53', '986')}${field('58', 'BR')}${field('59', 'LOJA')}'
        '${field('60', 'RIO')}${field('62', field('05', '***'))}6304';

    await scan(tester, '$body${PixBrCodeParser.crc16(body)}');

    expect(
      find.text(
        pixHubFailureMessage(
          t,
          const PixHubFailure(PixHubErrorCode.unsupportedCode),
        ),
      ),
      findsOneWidget,
    );
    expect(controller.state.draft, isNull);
    expect(scanner(tester).found, isFalse);
  });

  testWidgets('a failed camera leads to Pix Copy and Paste', (tester) async {
    final camera = MobileScannerController(autoStart: false)
      ..value = const MobileScannerState.uninitialized().copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
    await openScan(tester, camera: camera);

    expect(find.text(t.pix_hub_scan_unavailable_body), findsOneWidget);

    await tester.tap(find.text(t.pix_hub_action_copy_paste));
    await tester.pumpAndSettle();
    expect(find.text('copy and paste'), findsOneWidget);

    // The step replaced the camera, so back returns to the hub.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('hub'), findsOneWidget);
  });
}
