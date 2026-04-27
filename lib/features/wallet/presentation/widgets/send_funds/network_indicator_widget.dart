import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';

class NetworkIndicatorWidget extends ConsumerWidget {
  const NetworkIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final address = ref.watch(addressStateProvider);

    if (address.isEmpty) {
      return const SizedBox.shrink();
    }

    final networkType = ref.watch(networkDetectionProvider(address));

    if (networkType == NetworkType.unknown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              t.wallet_send_network_unidentified,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getNetworkColor(networkType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getNetworkColor(networkType), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getNetworkIcon(networkType),
            size: 16,
            color: _getNetworkColor(networkType),
          ),
          const SizedBox(width: 4),
          Text(
            _getNetworkLabel(t, networkType),
            style: TextStyle(
              color: _getNetworkColor(networkType),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNetworkColor(NetworkType type) {
    switch (type) {
      case NetworkType.bitcoin:
        return Colors.orange;
      case NetworkType.lightning:
        return Colors.yellow;
      case NetworkType.liquid:
        return Colors.blue;
      case NetworkType.unknown:
        return Colors.red;
    }
  }

  IconData _getNetworkIcon(NetworkType type) {
    switch (type) {
      case NetworkType.bitcoin:
        return Icons.link;
      case NetworkType.lightning:
        return Icons.flash_on;
      case NetworkType.liquid:
        return Icons.water_drop;
      case NetworkType.unknown:
        return Icons.error_outline;
    }
  }

  String _getNetworkLabel(AppLocalizations t, NetworkType type) {
    switch (type) {
      case NetworkType.bitcoin:
        return t.wallet_send_network_bitcoin;
      case NetworkType.lightning:
        return t.wallet_send_network_lightning;
      case NetworkType.liquid:
        return t.wallet_send_network_liquid;
      case NetworkType.unknown:
        return t.wallet_send_network_unknown;
    }
  }
}
