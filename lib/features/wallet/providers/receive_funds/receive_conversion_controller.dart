import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Controller to manage all conversion logic when receiving
class ReceiveConversionController extends StateNotifier<void> {
  final Ref ref;

  ReceiveConversionController(this.ref) : super(null);

  /// Returns the correct value based on the conversion type
  String getCurrentValueForType(ReceiveConversionType conversionType) {
    switch (conversionType) {
      case ReceiveConversionType.asset:
        return ref.read(receiveAssetValueProvider);
      case ReceiveConversionType.sats:
        return ref.read(receiveSatsValueProvider);
      case ReceiveConversionType.fiat:
        return ref.read(receiveFiatValueProvider);
    }
  }

  /// Updates the provider corresponding to the current type
  void updateCurrentValueProvider(
    ReceiveConversionType conversionType,
    String value,
  ) {
    switch (conversionType) {
      case ReceiveConversionType.asset:
        ref.read(receiveAssetValueProvider.notifier).state = value;
        break;
      case ReceiveConversionType.sats:
        ref.read(receiveSatsValueProvider.notifier).state = value;
        break;
      case ReceiveConversionType.fiat:
        ref.read(receiveFiatValueProvider.notifier).state = value;
        break;
    }
  }

  /// Updates the final amount in asset for validation
  void updateFinalAmountValue(
    String inputValue,
    ReceiveConversionType conversionType,
    Asset selectedAsset,
  ) {
    if (inputValue.isEmpty) {
      ref.read(receiveAmountProvider.notifier).state = '';
      return;
    }

    final inputDouble = double.tryParse(inputValue);
    if (inputDouble == null || inputDouble <= 0) {
      ref.read(receiveAmountProvider.notifier).state = '';
      return;
    }

    String finalValue;

    switch (conversionType) {
      case ReceiveConversionType.asset:
        finalValue = inputValue;
        break;

      case ReceiveConversionType.sats:
        if (selectedAsset == Asset.btc) {
          final btcValue = inputDouble / 100000000;
          finalValue = btcValue.toString();
        } else {
          finalValue = inputValue;
        }
        break;

      case ReceiveConversionType.fiat:
        _convertFiatToAsset(inputValue, selectedAsset);
        return;
    }

    ref.read(receiveAmountProvider.notifier).state = finalValue;

    final doubleValue = double.tryParse(finalValue);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );
    validationController.validateAmount(doubleValue, AmountDisplayMode.bitcoin);
  }

  /// Converts fiat value to asset asynchronously
  Future<void> _convertFiatToAsset(
    String inputValue,
    Asset selectedAsset,
  ) async {
    final inputDouble = double.tryParse(inputValue);
    if (inputDouble == null || inputDouble <= 0) return;

    ref.read(receiveConversionLoadingProvider.notifier).state = true;

    try {
      final priceResult = await ref.read(
        fiatPriceProvider(selectedAsset).future,
      );

      priceResult.fold(
        (error) {
          print('Error fetching price for conversion: $error');
          ref.read(receiveAmountProvider.notifier).state = '';
        },
        (price) {
          if (price <= 0) {
            print('Invalid price received: $price');
            ref.read(receiveAmountProvider.notifier).state = '';
            return;
          }

          final assetValue = inputDouble / price;
          String finalValue;

          if (selectedAsset == Asset.btc) {
            finalValue = assetValue
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          } else {
            finalValue = assetValue
                .toStringAsFixed(6)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          }

          ref.read(receiveAmountProvider.notifier).state = finalValue;

          final validationController = ref.read(
            receiveValidationControllerProvider.notifier,
          );
          validationController.validateAmount(
            assetValue,
            AmountDisplayMode.bitcoin,
          );
        },
      );
    } catch (e) {
      print('Error in fiat conversion: $e');
      ref.read(receiveAmountProvider.notifier).state = '';
    } finally {
      ref.read(receiveConversionLoadingProvider.notifier).state = false;
    }
  }

  /// Changes the conversion type and syncs the values
  void changeConversionType(
    ReceiveConversionType newType,
    Asset selectedAsset,
  ) {
    ref.read(receiveConversionLoadingProvider.notifier).state = false;
    ref.read(receiveConversionTypeProvider.notifier).state = newType;
    _syncValuesOnTypeChange(newType, selectedAsset);
  }

  /// Syncs values when the conversion type changes
  void _syncValuesOnTypeChange(
    ReceiveConversionType newType,
    Asset selectedAsset,
  ) {
    final currentAssetValue = ref.read(receiveAmountProvider);
    if (currentAssetValue.isEmpty) return;

    final assetDouble = double.tryParse(currentAssetValue);
    if (assetDouble == null || assetDouble <= 0) return;

    switch (newType) {
      case ReceiveConversionType.asset:
        ref.read(receiveAssetValueProvider.notifier).state = currentAssetValue;
        break;

      case ReceiveConversionType.sats:
        if (selectedAsset == Asset.btc) {
          final satsValue = (assetDouble * 100000000).round();
          ref.read(receiveSatsValueProvider.notifier).state =
              satsValue.toString();
        }
        break;

      case ReceiveConversionType.fiat:
        _convertAssetToFiat(currentAssetValue, selectedAsset);
        break;
    }
  }

  /// Converts asset value to fiat
  Future<void> _convertAssetToFiat(
    String assetValue,
    Asset selectedAsset,
  ) async {
    final assetDouble = double.tryParse(assetValue);
    if (assetDouble == null || assetDouble <= 0) return;

    try {
      final priceResult = await ref.read(
        fiatPriceProvider(selectedAsset).future,
      );

      priceResult.fold(
        (error) {
          print('Error fetching price for reverse conversion: $error');
        },
        (price) {
          if (price <= 0) return;

          final fiatValue = assetDouble * price;
          ref.read(receiveFiatValueProvider.notifier).state = fiatValue
              .toStringAsFixed(2);
        },
      );
    } catch (e) {
      print('Error in reverse conversion: $e');
    }
  }

  /// Returns the suffix text based on the conversion type
  String getSuffixText(
    Asset? selectedAsset,
    ReceiveConversionType conversionType,
  ) {
    if (selectedAsset == null) return '';

    switch (conversionType) {
      case ReceiveConversionType.asset:
        return selectedAsset.ticker;
      case ReceiveConversionType.sats:
        return selectedAsset == Asset.btc ? 'sats' : selectedAsset.ticker;
      case ReceiveConversionType.fiat:
        // Returns empty here because it needs ref in context
        return '';
    }
  }
}

/// Provider for the conversion controller
final receiveConversionControllerProvider =
    StateNotifierProvider<ReceiveConversionController, void>((ref) {
      return ReceiveConversionController(ref);
    });
