import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/payment_request_applier.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

const _bitcoin = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';
const _liquid =
    'lq1qqw0j4k82lz2eek432qgm59v9ru4qz436rrlkc7j0hd69nfujhz5z2d4nv620upes7u949hhw2r97vcsvp7e3kkvm9tx0edq6t';

void main() {
  group('PaymentRequestApplier.displayAddress', () {
    test('strips BIP21 scheme and query', () {
      expect(
        PaymentRequestApplier.displayAddress(
          'bitcoin:bc1qxyz?amount=0.5&label=x',
        ),
        'bc1qxyz',
      );
      expect(
        PaymentRequestApplier.displayAddress('liquidnetwork:lq1abc?assetid=1'),
        'lq1abc',
      );
    });

    test('leaves plain addresses untouched', () {
      expect(PaymentRequestApplier.displayAddress('bc1qxyz'), 'bc1qxyz');
      expect(PaymentRequestApplier.displayAddress(''), '');
    });
  });

  group('PaymentRequestApplier.autoSwitchAsset', () {
    late WidgetRef ref;
    late ProviderContainer container;

    /// A send form on [asset] with an amount of 50 000 sats, set with "max"
    /// when [max].
    Future<void> form(
      WidgetTester tester, {
      required Asset asset,
      bool max = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, widgetRef, _) {
              ref = widgetRef;
              return const SizedBox();
            },
          ),
        ),
      );
      container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(selectedAssetProvider.notifier).state = asset;
      container.read(amountStateProvider.notifier).state = 50000;
      container.read(maxSendRequestedProvider.notifier).state = max;
    }

    testWidgets('a pasted address of the other network switches the asset, '
        'and puts the amount and max back to zero', (tester) async {
      for (final (from, address, to) in [
        (Asset.btc, _liquid, Asset.lbtc),
        (Asset.lbtc, _bitcoin, Asset.btc),
      ]) {
        await form(tester, asset: from, max: true);

        PaymentRequestApplier.autoSwitchAsset(ref, address);

        expect(container.read(selectedAssetProvider), to, reason: '$from');
        expect(container.read(amountStateProvider), 0, reason: '$from');
        expect(container.read(maxSendRequestedProvider), isFalse);
      }
    });

    testWidgets('an address of the selected network keeps the amount', (
      tester,
    ) async {
      await form(tester, asset: Asset.btc, max: true);

      PaymentRequestApplier.autoSwitchAsset(ref, _bitcoin);

      expect(container.read(selectedAssetProvider), Asset.btc);
      expect(container.read(amountStateProvider), 50000);
      expect(container.read(maxSendRequestedProvider), isTrue);
    });

    testWidgets('a token keeps its amount: a Liquid address does not '
        'switch it', (tester) async {
      await form(tester, asset: Asset.usdt);

      PaymentRequestApplier.autoSwitchAsset(ref, _liquid);

      expect(container.read(selectedAssetProvider), Asset.usdt);
      expect(container.read(amountStateProvider), 50000);
    });

    testWidgets('a request for another asset resets the typed amount, and '
        'its own amount applies', (tester) async {
      await form(tester, asset: Asset.lbtc, max: true);
      final request = 'liquidnetwork:$_liquid?amount=100&assetid=$usdtAssetId';

      container.read(addressStateProvider.notifier).state = request;
      PaymentRequestApplier.autoSwitchAsset(ref, request);

      expect(container.read(selectedAssetProvider), Asset.usdt);
      expect(container.read(amountStateProvider), 0);
      expect(container.read(maxSendRequestedProvider), isFalse);
      expect(container.read(finalAmountProvider), greaterThan(0));
    });
  });
}
