import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final balanceProvider = FutureProvider.family<BigInt, Asset>((
  ref,
  Asset asset,
) async {
  final balances = await ref.watch(walletRepositoryProvider).getBalance();
  return balances[asset] ?? BigInt.zero;
});
