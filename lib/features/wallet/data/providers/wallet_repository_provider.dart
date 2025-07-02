import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import '../repositories/wallet_repository_impl.dart';
import '../repositories/fake_wallet_repository_impl.dart';
import '../../../../providers/wallet/breez_provider.dart';

part 'wallet_repository_provider.g.dart';

@riverpod
WalletRepository walletRepository(Ref ref) {
  // Use fake repository in debug mode, real repository in production
  if (kDebugMode) {
    return FakeWalletRepositoryImpl();
  } else {
    final breezRepository = ref.read(breezRepositoryProvider);
    // Note: This assumes breezRepository.client is initialized
    // You might need to handle the case where it's null
    if (breezRepository.client == null) {
      throw StateError('Breez client is not initialized');
    }
    return BreezWalletRepositoryImpl(breezRepository.client!);
  }
}
