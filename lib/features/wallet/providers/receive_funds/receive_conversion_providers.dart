import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for conversion types when receiving
enum ReceiveConversionType { asset, sats, fiat }

/// Provider for the final value in asset (used for QR code and validations)
final receiveAmountProvider = StateProvider<String>((ref) => '');

/// Provider for the current conversion type
final receiveConversionTypeProvider = StateProvider<ReceiveConversionType>(
  (ref) => ReceiveConversionType.asset,
);

/// Provider for the loading state of conversions
final receiveConversionLoadingProvider = StateProvider<bool>((ref) => false);

/// Separate controllers for each conversion type
final receiveAssetValueProvider = StateProvider<String>((ref) => '');
final receiveSatsValueProvider = StateProvider<String>((ref) => '');
final receiveFiatValueProvider = StateProvider<String>((ref) => '');
