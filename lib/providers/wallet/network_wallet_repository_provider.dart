import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/repositories/wallet/repository.dart';
import 'bitcoin_wallet_notifier.dart';
import 'liquid_wallet_notifier.dart';

part 'network_wallet_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref, Network network) {
  switch (network) {
    case Network.bitcoin:
      return ref.read(bitcoinWalletRepositoryProvider);
    case Network.liquid:
      return ref.read(liquidWalletRepositoryProvider);
  }
}
