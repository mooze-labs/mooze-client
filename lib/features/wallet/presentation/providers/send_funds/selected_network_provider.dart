import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'network_detection_provider.dart';
import 'address_provider.dart';

final selectedNetworkProvider = Provider<Blockchain>((ref) {
  final address = ref.watch(addressStateProvider);
  final networkType = ref.watch(networkDetectionProvider(address));

  switch (networkType) {
    case NetworkType.bitcoin:
      return Blockchain.bitcoin;
    case NetworkType.lightning:
      return Blockchain.lightning;
    case NetworkType.liquid:
      return Blockchain.liquid;
    case NetworkType.unknown:
      return Blockchain.liquid;
  }
});
