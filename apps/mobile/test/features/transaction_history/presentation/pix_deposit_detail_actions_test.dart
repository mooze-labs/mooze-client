import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/screens/pix_deposit_detail_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// A sample Pix copy-and-paste code. It is not a real Pix code.
const _code =
    '00020126580014br.gov.bcb.pix0136sample-code-of-the-test5204000053039865802BR';

/// A deposit created [age] ago, with the status [status].
PixDeposit _deposit(
  DepositStatus status, {
  Duration age = const Duration(minutes: 5),
  String? txid,
}) => PixDeposit(
  depositId: 'deposit-1',
  pixKey: _code,
  asset: Asset.depix,
  amountInCents: 10000,
  network: 'liquid',
  status: status,
  createdAt: DateTime.now().subtract(age),
  blockchainTxid: txid,
);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// The texts that the share sheet received.
  late List<String?> shared;

  setUp(() {
    shared = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            shared.add((call.arguments as Map)['text'] as String?);
            return 'dev.fluttercommunity.plus/share/unavailable';
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          null,
        );
  });

  /// Pumps frames. The step in progress breathes and the countdown ticks,
  /// so `pumpAndSettle` never ends.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls to the action [label] and taps it. The panel ends below the
  /// first screen, and the scroll lays out on the next frame.
  Future<void> tapAction(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    await tester.tap(find.text(label));
  }

  Future<void> open(WidgetTester tester, PixDeposit deposit) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: PixDepositDetailScreen(deposit: deposit),
        ),
      ),
    );
    await frames(tester);
  }

  // As on the payment link: a Pix that still pays can be shared, or shown
  // as a QR Code to a payer in person.
  group('a pending deposit, still valid', () {
    testWidgets('shares the amount and the Pix code', (tester) async {
      await open(tester, _deposit(DepositStatus.pending));

      await tapAction(tester, t.pix_deposit_share_action);
      await tester.pump();

      expect(shared, [
        t.pix_deposit_share_message(formatBrlCents(10000), _code),
      ]);
    });

    // The QR Code opens in the app: a chevron, as on the payment link.
    testWidgets('the QR Code action points inward', (tester) async {
      await open(tester, _deposit(DepositStatus.pending));

      expect(
        find.descendant(
          of: find.widgetWithText(InCardActionButton, t.pix_deposit_qr_action),
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows its QR Code in a floating sheet', (tester) async {
      await open(tester, _deposit(DepositStatus.pending));
      expect(find.byType(PixQrPanel), findsNothing);

      await tapAction(tester, t.pix_deposit_qr_action);
      await frames(tester);

      expect(find.byType(GlassSheet), findsOneWidget);
      expect(tester.widget<PixQrPanel>(find.byType(PixQrPanel)).data, _code);
      expect(find.text(t.pix_deposit_qr_caption), findsOneWidget);
    });
  });

  // A Pix that no longer pays would only fail for the payer, so it offers
  // no share and no QR Code.
  for (final (name, deposit) in [
    (
      'a pending deposit past its validity',
      _deposit(DepositStatus.pending, age: const Duration(minutes: 25)),
    ),
    ('a finished deposit', _deposit(DepositStatus.finished, txid: 'tx-1')),
    ('a failed deposit', _deposit(DepositStatus.failed)),
  ]) {
    testWidgets('$name offers no share and no QR Code', (tester) async {
      await open(tester, deposit);

      expect(find.text(t.pix_deposit_share_action), findsNothing);
      expect(find.text(t.pix_deposit_qr_action), findsNothing);
      expect(find.text(t.pix_deposit_title), findsOneWidget);
    });
  }

  testWidgets('a finished deposit keeps the explorer link', (tester) async {
    await open(tester, _deposit(DepositStatus.finished, txid: 'tx-1'));

    expect(find.text(t.pix_deposit_view_explorer), findsOneWidget);
  });
}
