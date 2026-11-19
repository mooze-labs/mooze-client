import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_details_sheet.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_address_field.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  const btcAddress = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';
  const liquidAddress =
      'lq1qqf8er278e6nyvuwtgf39e6ewvdcnjupn9a86rzpx655y5lhkt0walu3djf9cklkxd3'
      'ryld97hu8h3xepw7sh2rlu7q45dcew5';
  const txid =
      '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b';

  final btc = WalletAddress(
    address: btcAddress,
    chain: AddressChain.bitcoin,
    status: AddressStatus.used,
    derivationIndex: 3,
    utxos: [
      AddressUtxo(
        address: btcAddress,
        chain: AddressChain.bitcoin,
        outpoint: '$txid:0',
        value: BigInt.from(150000),
      ),
    ],
  );

  final liquid = WalletAddress(
    address: liquidAddress,
    chain: AddressChain.liquid,
    status: AddressStatus.used,
    derivationIndex: 7,
    utxos: [
      AddressUtxo(
        address: liquidAddress,
        chain: AddressChain.liquid,
        outpoint: '',
        value: BigInt.from(2500),
        assetId: lbtcAssetId,
      ),
      AddressUtxo(
        address: liquidAddress,
        chain: AddressChain.liquid,
        outpoint: '',
        value: BigInt.from(1000000000),
        assetId: usdtAssetId,
      ),
    ],
  );

  final unused = WalletAddress(
    address: btcAddress,
    chain: AddressChain.bitcoin,
    status: AddressStatus.unused,
    derivationIndex: 12,
  );

  /// What the app put on the clipboard.
  late List<String> clipboard;

  /// [tiles] in a glass panel, in Portuguese, on a phone screen.
  Future<void> pump(
    WidgetTester tester,
    List<WalletAddress> addresses, {
    Brightness brightness = Brightness.dark,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    clipboard = [];
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Theme(
            data: brightness == Brightness.dark
                ? AppTheme.darkTheme(context)
                : AppTheme.lightTheme(context),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassPanel(
                child: Column(
                  children: [
                    for (final address in addresses)
                      AddressTile(address: address),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(AddressDetailsSheet), matching: matching);

  testWidgets('a tap on an address opens a floating glass sheet with its '
      'QR code, its chain and index, and its full address', (tester) async {
    await pump(tester, [btc]);

    await tester.tap(find.byType(AddressTile));
    await tester.pumpAndSettle();

    expect(find.byType(AddressDetailsSheet), findsOneWidget);
    expect(inSheet(find.byType(GlassSheet)), findsOneWidget);
    expect(inSheet(find.text(t.address_explorer_full_address_title)), findsOne);
    expect(
      inSheet(
        find.text(
          t.address_explorer_search_match_at_index(
            t.address_explorer_tab_onchain,
            3,
          ),
        ),
      ),
      findsOneWidget,
    );
    final qr = tester.widget<PixQrPanel>(inSheet(find.byType(PixQrPanel)));
    expect(qr.data, btcAddress);
    expect(inSheet(find.byType(PrettyQrView)), findsOneWidget);
    final field = tester.widget<ReceiveAddressField>(
      inSheet(find.byType(ReceiveAddressField)),
    );
    expect(field.address, btcAddress);
  });

  testWidgets('a tap on the address in the sheet copies the full address', (
    tester,
  ) async {
    await pump(tester, [liquid]);
    await tester.tap(find.byType(AddressTile));
    await tester.pumpAndSettle();

    await tester.tap(inSheet(find.byType(ReceiveAddressField)));
    await tester.pump();
    expect(clipboard, [liquidAddress]);

    // The check of the field turns back into the copy icon.
    await tester.pump(ReceiveAddressField.copiedDuration);
  });

  testWidgets('the sheet lists the UTXOs: a bitcoin outpoint, and each '
      'Liquid asset by name', (tester) async {
    await pump(tester, [btc, liquid]);

    await tester.tap(find.byType(AddressTile).first);
    await tester.pumpAndSettle();
    expect(inSheet(find.text(t.address_explorer_utxo_count(1))), findsOne);
    expect(inSheet(find.text('4a5e1e4b…a33b')), findsOneWidget);
    await tester.tap(find.byTooltip(t.common_close));
    await tester.pumpAndSettle();
    expect(find.byType(AddressDetailsSheet), findsNothing);

    await tester.tap(find.byType(AddressTile).last);
    await tester.pumpAndSettle();
    expect(inSheet(find.text(t.address_explorer_utxo_count(2))), findsOne);
    expect(inSheet(find.text(Asset.lbtc.name)), findsOneWidget);
    expect(inSheet(find.text(Asset.usdt.name)), findsOneWidget);
    expect(
      inSheet(find.text(Asset.usdt.formatBalance(BigInt.from(1000000000)))),
      findsOneWidget,
    );
  });

  testWidgets('an address without UTXOs shows its status and no list', (
    tester,
  ) async {
    await pump(tester, [unused]);

    await tester.tap(find.byType(AddressTile));
    await tester.pumpAndSettle();

    expect(
      inSheet(
        find.text(
          '${t.address_explorer_status_unused} · '
          '${t.address_explorer_utxo_count(0)}',
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
    expect(inSheet(find.text(t.address_explorer_utxo_count(0))), findsNothing);
  });

  testWidgets('the copy button of a row copies the address and keeps the '
      'list in view', (tester) async {
    await pump(tester, [btc]);

    await tester.tap(find.byTooltip(t.address_explorer_full_address_copy));
    await tester.pump();

    expect(clipboard, [btcAddress]);
    expect(find.byType(AddressDetailsSheet), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('many UTXOs scroll inside the sheet on a short screen', (
    tester,
  ) async {
    final many = WalletAddress(
      address: btcAddress,
      chain: AddressChain.bitcoin,
      status: AddressStatus.used,
      derivationIndex: 0,
      utxos: [
        for (var i = 0; i < 30; i++)
          AddressUtxo(
            address: btcAddress,
            chain: AddressChain.bitcoin,
            outpoint: '$txid:$i',
            value: BigInt.from(1000 + i),
          ),
      ],
    );
    await pump(tester, [many], size: const Size(320, 568));

    await tester.tap(find.byType(AddressTile));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(inSheet(find.byType(SingleChildScrollView)), findsOneWidget);
    // The header stays in view while the list scrolls.
    await tester.drag(
      inSheet(find.byType(SingleChildScrollView)),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    expect(inSheet(find.text(t.address_explorer_full_address_title)), findsOne);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the sheet fits a 320 pt screen at 200% text in the '
        '${brightness.name} theme', (tester) async {
      await pump(
        tester,
        [liquid],
        brightness: brightness,
        size: const Size(320, 640),
        textScale: 2,
      );

      await tester.tap(find.byType(AddressTile));
      await tester.pumpAndSettle();

      expect(find.byType(AddressDetailsSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
