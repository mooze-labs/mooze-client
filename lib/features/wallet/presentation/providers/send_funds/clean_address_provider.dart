import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'address_provider.dart';

/// Provider that extracts just the address part from potentially complex URIs
/// Used for transaction building where only the address is needed
final cleanAddressProvider = Provider<String>((ref) {
  final fullAddress = ref.watch(addressStateProvider);

  if (fullAddress.isEmpty) {
    return '';
  }

  // Handle BIP21 URIs
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

  // For plain addresses, return as is
  return fullAddress;
});
