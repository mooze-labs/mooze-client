import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import './wallet_repository_impl.dart';

part 'wallet_repository_provider.g.dart';

@riverpod
WalletRepository walletRepository(Ref ref, BindingLiquidSdk breez) {
  return BreezWalletRepositoryImpl(breez);
}
