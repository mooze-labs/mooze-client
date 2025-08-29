import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkType { bitcoin, lightning, liquid, unknown }

class NetworkDetectionService {
  static NetworkType detectNetworkType(String address) {
    if (address.isEmpty) return NetworkType.unknown;

    // Lightning Network detection
    if (address.toLowerCase().startsWith('lnbc') ||
        address.toLowerCase().startsWith('lightning:') ||
        address.toLowerCase().contains('@')) {
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
        address.startsWith('ert1')) {
      return NetworkType.liquid;
    }

    // Bitcoin on-chain detection
    if (address.startsWith('bc1') || // Bech32 (native SegWit)
        address.startsWith('3') || // P2SH (SegWit compatible)
        address.startsWith('1') || // Legacy P2PKH
        address.startsWith('tb1') || // Testnet bech32
        address.startsWith('2') || // Testnet P2SH
        address.startsWith('m') || // Testnet legacy
        address.startsWith('n')) {
      // Testnet legacy
      return NetworkType.bitcoin;
    }

    return NetworkType.unknown;
  }
}

final networkDetectionProvider = Provider.family<NetworkType, String>((
  ref,
  address,
) {
  return NetworkDetectionService.detectNetworkType(address);
});
