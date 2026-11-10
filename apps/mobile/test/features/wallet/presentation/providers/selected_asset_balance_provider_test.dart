import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';

void main() {
  /// The balance line of [asset], with 1234 base units.
  Future<String> balanceOf(Asset asset) async {
    final container = ProviderContainer(
      overrides: [
        selectedAssetProvider.overrideWith((ref) => asset),
        balanceProvider.overrideWith(
          (ref, asset) async => right(BigInt.from(1234)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final balance = await container.read(selectedAssetBalanceProvider.future);
    return balance.getOrElse((_) => fail('no balance'));
  }

  test('BTC and L-BTC balances show in sats', () async {
    final sats = '${SatsInputFormatter.formatValue(1234)} sats';

    expect(await balanceOf(Asset.btc), sats);
    expect(await balanceOf(Asset.lbtc), sats);
  });

  test('a token balance shows in its unit', () async {
    expect(
      await balanceOf(Asset.usdt),
      Asset.usdt.formatBalance(BigInt.from(1234)),
    );
  });
}
