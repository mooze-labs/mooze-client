import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/receive_funds/receive_qr_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_transaction_item.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_address_field.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';

import '../../../../../shared/test_app.dart';

const _uri = 'bitcoin:bc1qtest?amount=0.001';
const _address = 'bc1qtest';
const _liquidAddress = 'lq1qqtest';
const _usdtId =
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';
const _liquidUri =
    'liquidnetwork:$_liquidAddress?amount=10.00000000&assetid=$_usdtId';
const _liquidNoAmountUri = 'liquidnetwork:$_liquidAddress?assetid=$_usdtId';

/// Gives the test a phone screen, so the whole QR screen is built.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('ReceiveQRScreen', () {
    /// What reached the clipboard, in order.
    late List<String?> copied;

    /// The screen of a request whose QR data is [request], as the receive
    /// flow opens it: the same text as the QR data and the address.
    Future<void> pumpRequest(
      WidgetTester tester, {
      required String request,
      Asset asset = Asset.btc,
      NetworkType network = NetworkType.bitcoin,
      double? amount = 0.001,
    }) async {
      _phone(tester);
      copied = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String?);
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
      await tester.pumpWidget(
        ProviderScope(
          child: wrapForTest(
            ReceiveQRScreen(
              qrData: request,
              displayAddress: request,
              asset: asset,
              network: network,
              amount: amount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // The QR code carries the whole request: a wallet that scans it fills
    // the asset and the amount. The field below is for pasting the
    // address alone, which every wallet and exchange accepts.
    for (final (request, address, asset, network, amount) in [
      (_uri, _address, Asset.btc, NetworkType.bitcoin, 0.001),
      (_liquidUri, _liquidAddress, Asset.usdt, NetworkType.liquid, 10.0),
      // A stablecoin request names its asset even without an amount.
      (
        _liquidNoAmountUri,
        _liquidAddress,
        Asset.usdt,
        NetworkType.liquid,
        null,
      ),
    ]) {
      testWidgets('the address field shows and copies only the bare '
          'address of $request', (tester) async {
        await pumpRequest(
          tester,
          request: request,
          asset: asset,
          network: network,
          amount: amount,
        );

        final field = tester.widget<ReceiveAddressField>(
          find.byType(ReceiveAddressField),
        );
        expect(field.address, address);
        expect(find.text(address), findsOneWidget);
        expect(find.textContaining('?'), findsNothing);
        // The QR code keeps the whole request.
        expect(
          tester.widget<PixQrPanel>(find.byType(PixQrPanel)).data,
          request,
        );

        await tester.tap(find.byType(ReceiveAddressField));
        await tester.pump();
        expect(copied, [address]);
        await tester.pump(ReceiveAddressField.copiedDuration);
      });
    }

    testWidgets('a tap on the QR code copies the whole request, with its '
        'asset and amount, and says so', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpRequest(
        tester,
        request: _liquidUri,
        asset: Asset.usdt,
        network: NetworkType.liquid,
        amount: 10,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('QR Code')),
        isSemantics(isButton: true, hasTapAction: true, hint: 'Copiar'),
      );

      await tester.tap(find.byType(PixQrPanel));
      await tester.pump();
      expect(copied, [_liquidUri]);
      expect(find.text('Endereço completo copiado'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      semantics.dispose();
    });

    testWidgets('the address field shows only the copy icon, never the '
        'word, and the icon turns into a check', (tester) async {
      await pumpRequest(tester, request: _uri);
      PixIconData icon() => tester
          .widget<PixIcon>(
            find.descendant(
              of: find.byType(ReceiveAddressField),
              matching: find.byType(PixIcon),
            ),
          )
          .icon;

      expect(find.text('Copiar'), findsNothing);
      expect(icon(), PixIcons.copy);

      await tester.tap(find.byType(ReceiveAddressField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Copiado!'), findsNothing);
      expect(icon(), PixIcons.check);

      await tester.pump(ReceiveAddressField.copiedDuration);
      await tester.pump(const Duration(milliseconds: 300));
      expect(icon(), PixIcons.copy);
    });

    testWidgets('shows the exact QR data on the shared backdrop', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: wrapForTest(
            const ReceiveQRScreen(
              qrData: _uri,
              displayAddress: _address,
              asset: Asset.btc,
              network: NetworkType.bitcoin,
              amount: 0.001,
              description: 'Almoço',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final panel = tester.widget<PixQrPanel>(find.byType(PixQrPanel));
      expect(panel.data, _uri);
      expect(panel.semanticLabel, 'QR Code');
      expect(find.byType(AppBackdrop), findsWidgets);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Compartilhar'), findsOneWidget);
      expect(find.text('Almoço'), findsOneWidget);
    });
  });

  group('AssetSelectorReceive', () {
    Future<ProviderContainer> pumpSelector(
      WidgetTester tester, {
      AsyncValue<Either<String, List<WalletHolding>>>? holdings,
      bool hidden = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletHoldingsProvider.overrideWithValue(
              holdings ?? AsyncValue.data(Right(_holdings)),
            ),
            isVisibleProvider.overrideWith((ref) => _FixedVisibility(hidden)),
          ],
          child: wrapForTest(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20),
                child: AssetSelectorReceive(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(AssetSelectorReceive)),
      );
    }

    testWidgets('picks an asset from a glass sheet and resets the request', (
      tester,
    ) async {
      final container = await pumpSelector(tester);
      container.read(receiveDescriptionProvider.notifier).state = 'Almoço';
      container.read(receiveAmountProvider.notifier).state = '0.001';

      await tester.tap(find.byType(AssetSelectorReceive));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsOneWidget);

      await tester.tap(find.text('USDt'));
      await tester.pumpAndSettle();

      expect(find.byType(GlassSheet), findsNothing);
      expect(container.read(selectedReceiveAssetProvider), Asset.usdt);
      expect(container.read(receiveDescriptionProvider), '');
      expect(container.read(receiveAmountProvider), '');
      expect(
        container.read(receiveConversionTypeProvider),
        ReceiveConversionType.asset,
      );
    });

    testWidgets('a dismissed sheet keeps the request', (tester) async {
      final container = await pumpSelector(tester);
      container.read(receiveDescriptionProvider.notifier).state = 'Almoço';

      await tester.tap(find.byType(AssetSelectorReceive));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(container.read(selectedReceiveAssetProvider), Asset.btc);
      expect(container.read(receiveDescriptionProvider), 'Almoço');
    });

    testWidgets('the sheet shows the balance of each asset', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSelector(tester);
      await tester.tap(find.byType(AssetSelectorReceive));
      await tester.pumpAndSettle();

      expect(find.text('125.000 sats'), findsOneWidget);
      expect(find.text(r'R$ 625,00'), findsOneWidget);
      expect(find.text('0 sat'), findsOneWidget);
      // Without a price, the row shows the amount and no status text.
      expect(find.text('10,00 USDT'), findsOneWidget);
      expect(find.text('Preço indisponível'), findsNothing);
      // A screen reader reads the amount as the value of the asset.
      expect(
        tester.getSemantics(find.bySemanticsLabel('BTC, Bitcoin')).value,
        '125.000 sats',
      );
      handle.dispose();
    });

    testWidgets('with large text, the balance goes below the name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSelector(tester);
      await tester.tap(find.byType(AssetSelectorReceive));
      await tester.pumpAndSettle();

      final name = find.descendant(
        of: find.byType(GlassSheet),
        matching: find.text('Bitcoin'),
      );
      expect(
        tester.getTopLeft(find.text('125.000 sats')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(name).dy),
      );
    });

    testWidgets('hidden balances show a mask', (tester) async {
      await pumpSelector(tester, hidden: true);
      await tester.tap(find.byType(AssetSelectorReceive));
      await tester.pumpAndSettle();

      expect(find.text(holdingMask), findsNWidgets(_holdings.length));
      expect(find.text('125.000 sats'), findsNothing);
      expect(find.text(r'R$ 625,00'), findsNothing);
    });

    testWidgets('loading balances show a skeleton', (tester) async {
      await pumpSelector(tester, holdings: const AsyncValue.loading());
      await tester.tap(find.byType(AssetSelectorReceive));
      // The skeleton shimmers, so the test pumps past the sheet animation
      // instead of waiting for the screen to settle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SkeletonBox), findsNWidgets(4));
    });
  });
}

/// Balances of the picker tests. Depix has none, so its row shows no
/// amount.
final _holdings = [
  WalletHolding(
    asset: Asset.btc,
    balance: BigInt.from(125000),
    fiatValue: 625,
    formattedBalance: '125.000 sats',
    formattedFiatValue: r'R$ 625,00',
    hasBalance: true,
  ),
  WalletHolding(
    asset: Asset.lbtc,
    balance: BigInt.zero,
    fiatValue: 0,
    formattedBalance: '0 sat',
    formattedFiatValue: r'R$ 0,00',
    hasBalance: false,
  ),
  WalletHolding(
    asset: Asset.usdt,
    balance: BigInt.from(1000000000),
    formattedBalance: '10,00 USDT',
    formattedFiatValue: 'Preço indisponível',
    hasBalance: true,
  ),
];

/// Balance visibility with a fixed start value. The app notifier reads
/// the stored setting, which the tests do not have.
class _FixedVisibility extends StateNotifier<bool>
    implements VisibilityNotifier {
  _FixedVisibility(super.hidden);

  @override
  Future<void> setVisibility(bool isVisible) async => state = isVisible;

  @override
  void toggle() => state = !state;
}
