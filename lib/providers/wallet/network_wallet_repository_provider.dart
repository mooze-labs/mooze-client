import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/repositories/wallet/wollet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/network.dart';
import 'bitcoin_provider.dart';
import 'liquid_provider.dart';

part 'network_wallet_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WolletRepository networkWolletRepository(Ref ref, Network network) {
  switch (network) {
    case Network.bitcoin:
      return ref.read(bitcoinWolletRepositoryProvider);
    case Network.liquid:
      return ref.read(liquidWolletRepositoryProvider);
  }
}
