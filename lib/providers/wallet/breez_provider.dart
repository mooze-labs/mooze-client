import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/node_config_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_id_provider.dart';
import 'package:mooze_mobile/repositories/wallet/breez.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'breez_provider.g.dart';

@riverpod
BreezRepository breezRepository(Ref ref) {
  final nodeConfig = ref.watch(nodeConfigRepositoryProvider);
  final walletId = ref.watch(walletIdProvider);

  return BreezRepository(nodeConfig, walletId);
}
