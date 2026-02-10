import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/payment/consts.dart'
    as AppColors;
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/send_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/send_conversion_widgets.dart';
import 'package:mooze_mobile/shared/formatters/btc_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets/buttons/text_button.dart';

enum SendConversionType { asset, sats, fiat }

extension SendConversionTypeExtension on SendConversionType {
  String get label {
    switch (this) {
      case SendConversionType.asset:
        return 'Ativo';
      case SendConversionType.sats:
        return 'Satoshis';
      case SendConversionType.fiat:
        return 'Fiat';
    }
  }

  IconData get icon {
    switch (this) {
      case SendConversionType.asset:
        return Icons.currency_bitcoin;
      case SendConversionType.sats:
        return Icons.bolt;
      case SendConversionType.fiat:
        return Icons.attach_money;
    }
  }
}

final sendConversionTypeProvider = StateProvider<SendConversionType>((ref) {
  return SendConversionType.fiat;
});

final sendAssetValueProvider = StateProvider<String>((ref) => '');
final sendSatsValueProvider = StateProvider<String>((ref) => '');
final sendFiatValueProvider = StateProvider<String>((ref) => '');
final sendConversionLoadingProvider = StateProvider<bool>((ref) => false);

class AmountFieldSend extends ConsumerStatefulWidget {
  const AmountFieldSend({super.key});

  @override
  ConsumerState<AmountFieldSend> createState() => _AmountFieldSendState();
}

class _AmountFieldSendState extends ConsumerState<AmountFieldSend> {
  late TextEditingController _textController;
  bool _isUpdatingFromProvider = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _getInputFormatters(
    Asset? selectedAsset,
    SendConversionType conversionType,
  ) {
    if (conversionType == SendConversionType.asset) {
      return [BtcInputFormatter()];
    }

    if (conversionType == SendConversionType.sats) {
      return [SatsInputFormatter()];
    }

    if (conversionType == SendConversionType.fiat) {
      return [FiatInputFormatter()];
    }

    return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
  }

  String _getCurrentValueForType(SendConversionType type) {
    switch (type) {
      case SendConversionType.asset:
        return ref.read(sendAssetValueProvider);
      case SendConversionType.sats:
        return ref.read(sendSatsValueProvider);
      case SendConversionType.fiat:
        return ref.read(sendFiatValueProvider);
    }
  }

  void _updateCurrentValueProvider(SendConversionType type, String value) {
    switch (type) {
      case SendConversionType.asset:
        ref.read(sendAssetValueProvider.notifier).state = value;
        break;
      case SendConversionType.sats:
        ref.read(sendSatsValueProvider.notifier).state = value;
        break;
      case SendConversionType.fiat:
        ref.read(sendFiatValueProvider.notifier).state = value;
        break;
    }
  }

  void _updateFinalAmountValue(
    String value,
    SendConversionType inputType,
    Asset selectedAsset,
  ) {
    if (value.isEmpty) {
      ref.read(amountStateProvider.notifier).state = 0;
      ref.read(sendAssetValueProvider.notifier).state = '';
      ref.read(sendSatsValueProvider.notifier).state = '';
      ref.read(sendFiatValueProvider.notifier).state = '';
      return;
    }

    final normalizedValue = value.replaceAll(',', '.');
    final double parsedValue = double.tryParse(normalizedValue) ?? 0.0;

    if (parsedValue <= 0) {
      return;
    }

    ref.read(sendConversionLoadingProvider.notifier).state = true;

    try {
      final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);
      final selectedAssetPriceAsync = ref.read(selectedAssetPriceProvider);

      final bitcoinPrice = bitcoinPriceAsync.value;
      final selectedAssetPrice = selectedAssetPriceAsync.value;

      final double? priceToUse =
          (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
              ? bitcoinPrice
              : selectedAssetPrice;

      double assetAmount = 0.0;
      int satsAmount = 0;
      double fiatAmount = 0.0;

      if (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) {
        switch (inputType) {
          case SendConversionType.asset:
            assetAmount = parsedValue;
            satsAmount = (parsedValue * 100000000).toInt();
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = parsedValue * priceToUse;
            }
            break;
          case SendConversionType.sats:
            satsAmount = parsedValue.toInt();
            assetAmount = satsAmount / 100000000;
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = assetAmount * priceToUse;
            }
            break;
          case SendConversionType.fiat:
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = parsedValue;
              assetAmount = fiatAmount / priceToUse;
              satsAmount = (assetAmount * 100000000).toInt();
            } else {
              ref.read(sendConversionLoadingProvider.notifier).state = false;
              return;
            }
            break;
        }
      } else {
        switch (inputType) {
          case SendConversionType.asset:
            assetAmount = parsedValue;
            satsAmount = (parsedValue * 100000000).toInt();
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = parsedValue * priceToUse;
            }
            break;
          case SendConversionType.sats:
            assetAmount = parsedValue;
            satsAmount = (parsedValue * 100000000).toInt();
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = assetAmount * priceToUse;
            }
            break;
          case SendConversionType.fiat:
            if (priceToUse != null && priceToUse > 0) {
              fiatAmount = parsedValue;
              assetAmount = fiatAmount / priceToUse;
              satsAmount = (assetAmount * 100000000).toInt();
            } else {
              ref.read(sendConversionLoadingProvider.notifier).state = false;
              return;
            }
            break;
        }
      }

      ref.read(amountStateProvider.notifier).state = satsAmount;

      if (inputType != SendConversionType.asset) {
        ref.read(sendAssetValueProvider.notifier).state = assetAmount
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
      if (inputType != SendConversionType.sats) {
        ref.read(sendSatsValueProvider.notifier).state = satsAmount.toString();
      }
      if (inputType != SendConversionType.fiat) {
        ref.read(sendFiatValueProvider.notifier).state = fiatAmount
            .toStringAsFixed(2);
      }
    } finally {
      ref.read(sendConversionLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNetwork = ref.watch(selectedNetworkProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);
    final validationState = ref.watch(sendValidationControllerProvider);
    final conversionType = ref.watch(sendConversionTypeProvider);
    final isConversionLoading = ref.watch(sendConversionLoadingProvider);

    final currentValue = _getCurrentValueForType(conversionType);

    if (!_isUpdatingFromProvider && _textController.text != currentValue) {
      _isUpdatingFromProvider = true;
      _textController.text = currentValue;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: currentValue.length),
      );
      _isUpdatingFromProvider = false;
    }

    final isDisabled = false;

    final amountError = validationState.errors.firstWhere(
      (error) =>
          error.contains('valor') ||
          error.contains('Valor') ||
          error.contains('mínimo'),
      orElse: () => '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Valor',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            SendConversionOptionsRow(selectedAsset: selectedAsset),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          enabled: !isDisabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _getInputFormatters(selectedAsset, conversionType),
          decoration: InputDecoration(
            hintText: 'Digite o valor',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixText: _getSuffixText(selectedAsset, conversionType),
            suffixIcon:
                isConversionLoading
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : _buildMaxButtonIcon(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
            errorText: amountError.isEmpty ? null : amountError,
          ),
          onChanged: (value) {
            if (_isUpdatingFromProvider) return;

            final conversionType = ref.read(sendConversionTypeProvider);

            String valueForController = value;
            if (conversionType == SendConversionType.sats) {
              final intValue = SatsInputFormatter.parseValue(value);
              valueForController = intValue.toString();
            } else if (conversionType == SendConversionType.fiat) {
              final doubleValue = FiatInputFormatter.parseValue(value);
              valueForController = doubleValue.toString();
            }

            _updateCurrentValueProvider(conversionType, value);
            _updateFinalAmountValue(
              valueForController,
              conversionType,
              selectedAsset,
            );
          },
        ),
        if (currentValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAmountInfo(context, selectedNetwork, selectedAsset),
        ],
      ],
    );
  }

  String _getSuffixText(
    Asset? selectedAsset,
    SendConversionType conversionType,
  ) {
    if (selectedAsset == null) return '';

    switch (conversionType) {
      case SendConversionType.asset:
        return selectedAsset.ticker;
      case SendConversionType.sats:
        return (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
            ? 'sats'
            : selectedAsset.ticker;
      case SendConversionType.fiat:
        final currencyNotifier = ref.read(currencyControllerProvider.notifier);
        return currencyNotifier.icon;
    }
  }

  Widget? _buildMaxButtonIcon() {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final selectedAssetBalance = ref.watch(selectedAssetBalanceRawProvider);

    return selectedAssetBalance.when(
      data:
          (data) => data.fold(
            (err) => null,

            (amount) => TransparentTextButton(
              text: 'MAX',
              onPressed: () => _setMaxAmount(selectedAsset, amount.toInt()),
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: AppColors.primaryColor),
            ),
          ),
      error: (err, _) => null,
      loading: () => null,
    );
  }

  void _setMaxAmount(Asset selectedAsset, int satsAmount) {
    final conversionType = ref.read(sendConversionTypeProvider);
    final bitcoinPriceAsync = ref.read(bitcoinPriceProvider);
    final selectedAssetPriceAsync = ref.read(selectedAssetPriceProvider);

    final bitcoinPrice = bitcoinPriceAsync.value;
    final selectedAssetPrice = selectedAssetPriceAsync.value;

    final double? priceToUse =
        (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
            ? bitcoinPrice
            : selectedAssetPrice;

    final assetAmount = satsAmount / 100000000;

    double? fiatAmount;
    if (priceToUse != null && priceToUse > 0) {
      fiatAmount = assetAmount * priceToUse;
    }

    ref.read(sendAssetValueProvider.notifier).state = assetAmount
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    ref.read(sendSatsValueProvider.notifier).state = satsAmount.toString();

    if (fiatAmount != null) {
      ref.read(sendFiatValueProvider.notifier).state = fiatAmount
          .toStringAsFixed(2);
    } else {
      ref.read(sendFiatValueProvider.notifier).state = '';
    }

    String valueToShow = '';
    switch (conversionType) {
      case SendConversionType.asset:
        valueToShow = assetAmount
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
        break;
      case SendConversionType.sats:
        valueToShow = SatsInputFormatter.formatValue(satsAmount);
        break;
      case SendConversionType.fiat:
        if (fiatAmount != null) {
          valueToShow = FiatInputFormatter.formatValue(fiatAmount);
        } else {
          ref.read(sendConversionTypeProvider.notifier).state =
              SendConversionType.sats;
          valueToShow = SatsInputFormatter.formatValue(satsAmount);
        }
        break;
    }

    setState(() {
      _isUpdatingFromProvider = true;
      _textController.text = valueToShow;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: valueToShow.length),
      );
      _isUpdatingFromProvider = false;
    });

    ref.read(amountStateProvider.notifier).state = satsAmount;
  }

  Widget _buildAmountInfo(
    BuildContext context,
    Blockchain network,
    Asset selectedAsset,
  ) {
    final amountInSats = ref.watch(amountStateProvider);
    final btcAmount = amountInSats / 100000000;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valor em Satoshis:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${SatsInputFormatter.formatValue(amountInSats)} sats',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          const SizedBox(height: 8),
          SendConversionPreview(
            selectedAsset: selectedAsset,
            assetAmount: btcAmount,
          ),
          const SizedBox(height: 8),
          _buildNetworkValidations(context, network, btcAmount),
        ],
      ),
    );
  }

  Widget _buildNetworkValidations(
    BuildContext context,
    Blockchain network,
    double btcAmount,
  ) {
    if (network == Blockchain.liquid || network == Blockchain.bitcoin) {
      return _buildValidationRow(
        context,
        icon: Icons.check_circle_outline,
        text: 'Valor válido!',
        color: Colors.green,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildValidationRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
