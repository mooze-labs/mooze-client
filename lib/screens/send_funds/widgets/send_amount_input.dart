import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import '../providers/send_user_input_provider.dart';

class SendAmountInput extends ConsumerStatefulWidget {
  const SendAmountInput({super.key});

  @override
  ConsumerState<SendAmountInput> createState() => _SendAmountInputState();
}

class _SendAmountInputState extends ConsumerState<SendAmountInput> {
  late TextEditingController _controller;
  bool _isFiatMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      _isFiatMode = !_isFiatMode;

      if (_controller.text.isNotEmpty) {
        final currentValue = _parseInputValue(_controller.text);
        final fiatPrice = ref
            .read(fiatPricesProvider)
            .when(
              data: (data) {
                final sendInput = ref.read(sendUserInputProvider);
                return data[sendInput.asset?.fiatPriceId] ?? 0.0;
              },
              loading: () => 0.0,
              error: (_, __) => 0.0,
            );

        if (currentValue > 0 && fiatPrice > 0) {
          if (_isFiatMode) {
            // Converting from crypto to fiat
            final fiatValue = currentValue * fiatPrice;
            _controller.text = fiatValue
                .toStringAsFixed(2)
                .replaceAll('.', ',');
          } else {
            // Converting from fiat to crypto
            final cryptoValue = currentValue / fiatPrice;
            final sendInput = ref.read(sendUserInputProvider);
            _controller.text = cryptoValue
                .toStringAsFixed(sendInput.asset?.precision ?? 8)
                .replaceAll('.', ',');
          }
        }
      }

      // Notify parent about the change
      _notifyAmountChanged();
    });
  }

  // Parse input that might contain comma or dot as decimal separator
  double _parseInputValue(String text) {
    if (text.isEmpty) return 0.0;
    // Convert any comma to a dot for parsing
    final normalizedText = text.replaceAll(',', '.');
    return double.tryParse(normalizedText) ?? 0.0;
  }

  void _notifyAmountChanged() {
    final currentValue = _parseInputValue(_controller.text);
    if (currentValue <= 0) {
      ref.read(sendUserInputProvider.notifier).setAmount(0);
      return;
    }

    final fiatPrice = ref
        .read(fiatPricesProvider)
        .when(
          data: (data) {
            final sendInput = ref.read(sendUserInputProvider);
            return data[sendInput.asset?.fiatPriceId] ?? 0.0;
          },
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

    // Always send the crypto amount to the parent component, regardless of the input mode
    if (_isFiatMode && fiatPrice > 0) {
      final cryptoAmount = currentValue / fiatPrice;
      final satoshiAmount = (cryptoAmount * pow(10, 8)).toInt();
      ref.read(sendUserInputProvider.notifier).setAmount(satoshiAmount);
    } else {
      final satoshiAmount = (currentValue * pow(10, 8)).toInt();
      ref.read(sendUserInputProvider.notifier).setAmount(satoshiAmount);
    }
  }

  String _getConversionText() {
    if (_controller.text.isEmpty) return "";

    final inputValue = _parseInputValue(_controller.text);
    if (inputValue <= 0) return "";

    final sendInput = ref.read(sendUserInputProvider);
    final fiatPrice = ref
        .read(fiatPricesProvider)
        .when(
          data: (data) => data[sendInput.asset?.fiatPriceId] ?? 0.0,
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

    if (fiatPrice == 0) return "Preço não disponível";

    if (_isFiatMode) {
      final cryptoAmount = inputValue / fiatPrice;
      return "≈ ${cryptoAmount.toStringAsFixed(sendInput.asset?.precision ?? 8).replaceAll('.', ',')} ${sendInput.asset?.ticker}";
    }

    final fiatAmount = inputValue * fiatPrice;
    final baseCurrency = ref.read(baseCurrencyProvider);
    return "≈ ${baseCurrency} ${fiatAmount.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  @override
  Widget build(BuildContext context) {
    final sendInput = ref.watch(sendUserInputProvider);
    final fiatPrices = ref.watch(fiatPricesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final ownedAsset = ref
        .watch(ownedAssetsNotifierProvider)
        .when(
          data:
              (ownedAssets) =>
                  sendInput.asset != null
                      ? ownedAssets.firstWhere(
                        (asset) => asset.asset.id == sendInput.asset!.id,
                        orElse: () => OwnedAsset.zero(sendInput.asset!),
                      )
                      : null,
          loading: () => null,
          error: (_, __) => null,
        );

    final fiatPrice = fiatPrices.when(
      data: (data) => data[sendInput.asset?.fiatPriceId] ?? 0.0,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final conversionText = _getConversionText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText:
                  _isFiatMode
                      ? "Digite o valor em ${baseCurrency}"
                      : "Digite o valor em ${sendInput.asset?.ticker}",
              hintStyle: TextStyle(
                fontFamily: "roboto",
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              prefixText: _isFiatMode ? '${baseCurrency} ' : "",
              prefixIcon: IconButton(
                icon: Text(
                  _isFiatMode ? baseCurrency : sendInput.asset?.ticker ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: "roboto",
                  ),
                ),
                onPressed: _toggleInputMode,
              ),
              suffixIcon:
                  ownedAsset != null && sendInput.networkFee != null
                      ? IconButton(
                        icon: Text(
                          "MAX",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: "roboto",
                          ),
                        ),
                        onPressed: () {
                          final maxAmount =
                              ownedAsset.amount -
                              sendInput.networkFee!.absoluteFees -
                              1;
                          if (_isFiatMode) {
                            // Convert to fiat using fiat price
                            final amountInFiat =
                                (maxAmount /
                                        pow(10, ownedAsset.asset.precision)) *
                                    fiatPrice -
                                1;
                            _controller.text = amountInFiat.toStringAsFixed(2);
                          } else {
                            // Keep in crypto units
                            final amount =
                                maxAmount / pow(10, ownedAsset.asset.precision);
                            _controller.text = amount.toStringAsFixed(
                              ownedAsset.asset.precision,
                            );
                          }
                          _notifyAmountChanged();
                        },
                      )
                      : null,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "roboto",
            ),
            keyboardType:
                (Platform.isIOS)
                    ? null
                    : TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
            inputFormatters: [
              // Allow numbers, a single comma or dot for the decimal
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              // Custom formatter to ensure only one decimal separator exists
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Count how many decimal separators (comma or dot) are in the text
                int commaCount = newValue.text.split(',').length - 1;
                int dotCount = newValue.text.split('.').length - 1;

                // If there's more than one total decimal separator, reject the edit
                if (commaCount + dotCount > 1) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            onChanged: (value) {
              _notifyAmountChanged();
              setState(() {});
            },
          ),
        ),

        if (conversionText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              conversionText,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
