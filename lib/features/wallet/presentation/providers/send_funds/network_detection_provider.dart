import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

enum NetworkType { bitcoin, lightning, liquid, unknown }

class NetworkDetectionService {
  static const _tag = 'NetworkDetection';

  static NetworkType detectNetworkType(String address) {
    final log = AppLoggerService();

    if (address.isEmpty) {
      log.debug(_tag, 'detectNetworkType called with empty address');
      return NetworkType.unknown;
    }

    // Lightning Network detection
    if (address.toLowerCase().startsWith('lnbc') ||
        address.toLowerCase().startsWith('lightning:') ||
        address.toLowerCase().startsWith('lnurl') ||
        address.toLowerCase().contains('@')) {
      log.debug(
        _tag,
        'Detected: Lightning — prefix: ${address.substring(0, address.length.clamp(0, 10))}',
      );
      return NetworkType.lightning;
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
