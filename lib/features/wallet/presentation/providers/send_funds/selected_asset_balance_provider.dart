import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers.dart';

import 'selected_asset_provider.dart';

final selectedAssetBalanceProvider = FutureProvider<
  Either<WalletError, String>
>((ref) async {
  final selectedAsset = ref.watch(selectedAssetProvider);
  final balance = await ref.read(balanceProvider(selectedAsset).future);

  return balance.map((balanceInSats) {
    if (selectedAsset.ticker == 'BTC' || selectedAsset.ticker == 'BTC L2') {
      final formattedSats = SatsInputFormatter.formatValue(
        balanceInSats.toInt(),
      );
      return '$formattedSats ${balanceInSats == BigInt.one ? 'sat' : 'sats'}';
    }
    return selectedAsset.formatBalance(balanceInSats);
  });
});

final selectedAssetBalanceRawProvider =
    FutureProvider<Either<WalletError, BigInt>>((ref) async {
      final selectedAsset = ref.watch(selectedAssetProvider);
      final balance = await ref.read(balanceProvider(selectedAsset).future);

      return balance;
    });
