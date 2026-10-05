import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

enum NetworkType { bitcoin, liquid, unknown }

class NetworkDetectionService {
  static const _tag = 'NetworkDetection';

  static bool isLightningAddress(String address) {
    final a = address.trim().toLowerCase();
    if (a.isEmpty) return false;
    return a.startsWith('lnbc') ||
        a.startsWith('lntb') ||
        a.startsWith('lnbcrt') ||
        a.startsWith('lightning:') ||
        a.startsWith('lnurl') ||
        // Lightning Address (user@domain) — never a chain address.
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(a);
  }

  static NetworkType detectNetworkType(String address) {
    final log = AppLoggerService();

    if (address.isEmpty) {
      log.debug(_tag, 'detectNetworkType called with empty address');
      return NetworkType.unknown;
    }

    if (isLightningAddress(address)) {
      log.debug(
        _tag,
        'Rejected: Lightning is not a supported destination — prefix: '
        '${address.substring(0, address.length.clamp(0, 10))}',
      );
      return NetworkType.unknown;
    }

    // Liquid Network detection
    if (address.startsWith('lq1') ||
        address.startsWith('VJL') ||
        address.startsWith('VT') ||
        address.startsWith('VG') ||
        address.startsWith('H') ||
        address.startsWith('G') ||
        address.startsWith('Az') ||
        address.startsWith('AzQ') ||
        address.startsWith('ert1') ||
        address.startsWith('liquid:') ||
        address.startsWith('liquidnetwork:')) {
      log.debug(
        _tag,
        'Detected: Liquid — prefix: ${address.substring(0, address.length.clamp(0, 10))}',
      );
      return NetworkType.liquid;
    }

    // Bitcoin on-chain detection
    if (address.startsWith('bc1') || // Bech32 (native SegWit)
        address.startsWith('3') || // P2SH (SegWit compatible)
        address.startsWith('1') || // Legacy P2PKH
        address.startsWith('tb1') || // Testnet bech32
        address.startsWith('2') || // Testnet P2SH
        address.startsWith('m') || // Testnet legacy
        address.startsWith('n') ||
        address.startsWith('bitcoin:')) {
      // Testnet legacy
      log.debug(
        _tag,
        'Detected: Bitcoin — prefix: ${address.substring(0, address.length.clamp(0, 10))}',
      );
      return NetworkType.bitcoin;
    }

    log.warning(
      _tag,
      'Unknown network type for address prefix: ${address.substring(0, address.length.clamp(0, 10))}...',
    );
    return NetworkType.unknown;
  }
}

final networkDetectionProvider = Provider.family<NetworkType, String>((
  ref,
  address,
) {
  return NetworkDetectionService.detectNetworkType(address);
});
