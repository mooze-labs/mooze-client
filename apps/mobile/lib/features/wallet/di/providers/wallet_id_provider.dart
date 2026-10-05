import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/services/wallet_id_service.dart';

final walletIdServiceProvider = Provider<WalletIdService>((ref) {
  return WalletIdService();
});

/// Resolves the current walletId. Lazy: first read generates and persists
/// a UUID v4; subsequent reads return the same value. Stable across app
/// restarts; wiped only by [WalletDataManager.deleteWallet].
final walletIdProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(walletIdServiceProvider);
  return service.getOrCreate();
});
