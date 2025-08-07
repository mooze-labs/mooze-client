import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers.dart';

import 'selected_asset_provider.dart';

final selectedAssetBalanceProvider = FutureProvider<Either<WalletError, BigInt>>((ref) async {
  final selectedAsset = ref.read(selectedAssetProvider);
  final balance = await ref.read(balanceProvider(selectedAsset).future);

  return balance;
});