import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import 'send_flow_parts.dart';

/// The network of the typed address, as a small badge below the field.
class NetworkIndicatorWidget extends ConsumerWidget {
  const NetworkIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(addressStateProvider);
    final networkType = address.isEmpty
        ? null
        : ref.watch(networkDetectionProvider(address));

    return SizeFadeSwitcher(
      alignment: AlignmentDirectional.topStart,
      child: networkType == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey(networkType),
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SendNetworkBadge(network: networkType),
              ),
            ),
    );
  }
}
