import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/interfaces/fee_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../swap/presentation/fixed_fee_provider.dart';

/// A fee source that is down.
class _NoFees implements FeeProvider {
  @override
  String get providerName => 'none';

  @override
  Future<BitcoinFeeEstimate?> fetchFeeEstimate() async => null;
}

void main() {
  late FixedFeeProvider fees;

  ProviderContainer container({
    Asset asset = Asset.btc,
    Blockchain network = Blockchain.bitcoin,
    FeeProvider? source,
  }) {
    fees = FixedFeeProvider();
    final container = ProviderContainer(
      overrides: [
        selectedAssetProvider.overrideWith((ref) => asset),
        selectedNetworkProvider.overrideWithValue(network),
        bitcoinFeeServiceProvider.overrideWithValue(
          BitcoinFeeService(providers: [source ?? fees]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('each speed sends at its rate', () async {
    final c = container();

    for (final (speed, rate) in [
      (FeeSpeed.low, 2),
      (FeeSpeed.medium, 5),
      (FeeSpeed.fast, 9),
    ]) {
      c.read(feeSpeedProvider.notifier).state = speed;
      expect(await c.read(bitcoinSendFeeRateProvider.future), rate);
    }
  });

  test('a custom rate replaces the speed, with no fee lookup', () async {
    final c = container();
    c.read(feeSpeedProvider.notifier).state = FeeSpeed.fast;

    c.read(customFeeRateProvider.notifier).state = 14;

    expect(await c.read(bitcoinSendFeeRateProvider.future), 14);
    expect(fees.fetches, 0);
  });

  test('a custom rate keeps its tenths', () async {
    final c = container();

    c.read(customFeeRateProvider.notifier).state = 0.5;

    expect(await c.read(bitcoinSendFeeRateProvider.future), 0.5);
  });

  test('clearing the custom rate goes back to the speed', () async {
    final c = container();
    c.read(customFeeRateProvider.notifier).state = 14;
    expect(await c.read(bitcoinSendFeeRateProvider.future), 14);

    c.read(customFeeRateProvider.notifier).state = null;

    expect(await c.read(bitcoinSendFeeRateProvider.future), 5);
  });

  test('other sends leave the rate to the wallet', () async {
    for (final (asset, network) in [
      (Asset.lbtc, Blockchain.liquid),
      (Asset.btc, Blockchain.liquid),
      (Asset.usdt, Blockchain.liquid),
    ]) {
      final c = container(asset: asset, network: network);
      c.read(customFeeRateProvider.notifier).state = 14;

      expect(await c.read(bitcoinSendFeeRateProvider.future), isNull);
    }
  });

  test('without fee rates, the wallet uses its default rate', () async {
    final c = container(source: _NoFees());

    expect(await c.read(bitcoinSendFeeRateProvider.future), isNull);
  });
}
