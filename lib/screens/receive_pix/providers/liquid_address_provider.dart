import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';

final liquidAddressProvider = FutureProvider<String>((ref) async {
  final liquidWallet = ref.watch(liquidWolletRepositoryProvider);
  return liquidWallet.generateAddress();
});
