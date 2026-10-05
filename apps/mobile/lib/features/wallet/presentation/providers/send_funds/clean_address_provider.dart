import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'address_provider.dart';

/// Provider that extracts just the address part from potentially complex URIs
/// Used for transaction building where only the address is needed
final cleanAddressProvider = Provider<String>((ref) {
  final fullAddress = ref.watch(addressStateProvider);

  if (fullAddress.isEmpty) {
    return '';
  }

  // Handle BIP21 URIs with prefixes
  if (fullAddress.startsWith('bitcoin:') ||
      fullAddress.startsWith('liquidnetwork:') ||
      fullAddress.startsWith('liquid:')) {
    try {
      final uri = Uri.parse(fullAddress);
      return uri.path;
    } catch (e) {
      // If parsing fails, return as is
      return fullAddress;
    }
  }

  // Handle lightning prefix
  if (fullAddress.toLowerCase().startsWith('lightning:')) {
    return fullAddress.replaceFirst(
      RegExp(r'^lightning:', caseSensitive: false),
      '',
    );
  }

  // Handle Liquid addresses with query parameters but no prefix
  if (_isLiquidAddressWithParams(fullAddress)) {
    // Extract just the address part (before the ?)
    return fullAddress.split('?').first;
  }

  // For plain addresses, return as is
  return fullAddress;
});

/// Provider that normalizes addresses for Breez SDK
/// Adds liquidnetwork: prefix to Liquid addresses with query parameters
final normalizedAddressForBreezProvider = Provider<String>((ref) {
  final fullAddress = ref.watch(addressStateProvider);

  if (fullAddress.isEmpty) {
    return '';
  }

  // Check if this is a Liquid address with query parameters but without prefix
  if (_isLiquidAddressWithParams(fullAddress) &&
      !fullAddress.startsWith('liquidnetwork:') &&
      !fullAddress.startsWith('liquid:')) {
    return 'liquidnetwork:$fullAddress';
  }

  return fullAddress;
});

/// Helper function to detect Liquid addresses with query parameters
bool _isLiquidAddressWithParams(String address) {
  // Check if it has query parameters
  if (!address.contains('?')) {
    return false;
  }

  // Extract the base address (before ?)
  final baseAddress = address.split('?').first;

  // Check if the base address starts with Liquid prefixes
  final liquidPrefixes = [
    'lq1', // Liquid bech32
    'VJL', // Liquid P2SH
    'VT', // Liquid P2SH
    'VG', // Liquid P2SH
    'H', // Liquid legacy
    'G', // Liquid legacy
    'Az', // Liquid confidential
    'AzQ', // Liquid confidential
    'ert1', // Liquid testnet
  ];

  return liquidPrefixes.any((prefix) => baseAddress.startsWith(prefix));
}
