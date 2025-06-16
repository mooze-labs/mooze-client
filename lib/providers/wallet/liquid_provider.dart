import 'package:mooze_mobile/providers/wallet/node_config_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_id_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/repositories/wallet/signer.dart';
import 'package:mooze_mobile/repositories/wallet/wollet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'liquid_provider.g.dart';

@Riverpod(keepAlive: true)
WolletRepository liquidWolletRepository(Ref ref) {
  return LiquidWolletRepository(
    ref.read(nodeConfigRepositoryProvider),
    ref.read(walletIdProvider),
  );
}

@Riverpod(keepAlive: true)
SignerRepository liquidSignerRepository(Ref ref) {
  return LiquidSignerRepository(
    ref.read(liquidWolletRepositoryProvider) as LiquidWolletRepository,
    ref.read(nodeConfigRepositoryProvider),
  );
}
