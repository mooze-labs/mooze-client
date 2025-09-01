import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';

final selectedReceiveNetworkProvider = StateProvider<NetworkType?>(
  (ref) => NetworkType.bitcoin,
);
final receiveNetworkCompatibilityProvider = Provider<bool>((ref) {
  final selectedNetwork = ref.watch(selectedReceiveNetworkProvider);

  return selectedNetwork != null;
});
