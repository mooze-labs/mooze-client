import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/data/providers/wallet_repository_provider.dart';

final assetsProvider = FutureProvider<List<Asset>>((ref) async {
  final balances = await ref.watch(walletRepositoryProvider).getBalance();
  return balances.keys.toList();
});
