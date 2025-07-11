import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final stablecoinsProvider = FutureProvider<Map<Asset, BigInt>>((ref) async {
  final balances = await ref.watch(walletRepositoryProvider).getBalance();
  final Map<Asset, BigInt> stablecoins = Map.from(balances)
    ..removeWhere((key, value) => key == Asset.btc);
  return stablecoins;
});
