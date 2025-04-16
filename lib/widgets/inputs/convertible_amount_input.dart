import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class ConvertibleAmountInput extends StatefulWidget {
  final String assetId;
  final String assetTicker;
  final String fiatCurrency;
  final int assetPrecision;
  final double fiatPrice;
  final TextEditingController? controller;
  final Function(double)? onAmountChanged;
  final int? fees;
  final int? maxAmount;

  const ConvertibleAmountInput({
    super.key,
    required this.assetId,
    required this.assetTicker,
    required this.fiatPrice,
    this.fiatCurrency = "BRL",
    this.assetPrecision = 8,
    this.controller,
    this.onAmountChanged,
    this.fees,
    this.maxAmount,
  });

  @override
  State<ConvertibleAmountInput> createState() => _ConvertibleAmountInputState();
}

class _ConvertibleAmountInputState extends State<ConvertibleAmountInput> {
  late TextEditingController _controller;
  bool _isFiatMode = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      _isFiatMode = !_isFiatMode;

      if (_controller.text.isNotEmpty) {
        final currentValue = _parseInputValue(_controller.text);
        if (currentValue > 0 && widget.fiatPrice > 0) {
          if (_isFiatMode) {
            // Converting from crypto to fiat
            final fiatValue = currentValue * widget.fiatPrice;
            _controller.text = fiatValue
                .toStringAsFixed(2)
                .replaceAll('.', ',');
          } else {
            // Converting from fiat to crypto
            final cryptoValue = currentValue / widget.fiatPrice;
            _controller.text = cryptoValue
                .toStringAsFixed(widget.assetPrecision)
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
    if (widget.onAmountChanged == null) return;

    final currentValue = _parseInputValue(_controller.text);
    if (currentValue <= 0) {
      widget.onAmountChanged!(0.0);
      return;
    }

    // Always send the crypto amount to the parent component, regardless of the input mode
    if (_isFiatMode && widget.fiatPrice > 0) {
      final cryptoAmount = currentValue / widget.fiatPrice;
      widget.onAmountChanged!(cryptoAmount);
    } else {
      widget.onAmountChanged!(currentValue);
    }
  }

  String _getConversionText() {
    if (_controller.text.isEmpty) return "";

    final inputValue = _parseInputValue(_controller.text);
    if (inputValue <= 0) return "";
    if (widget.fiatPrice == 0) return "Preço não disponível";

    if (_isFiatMode) {
      final cryptoAmount = inputValue / widget.fiatPrice;
      return "≈ ${cryptoAmount.toStringAsFixed(widget.assetPrecision).replaceAll('.', ',')} ${widget.assetTicker}";
    }

    final fiatAmount = inputValue * widget.fiatPrice;
    return "≈ ${widget.fiatCurrency} ${fiatAmount.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  @override
  Widget build(BuildContext context) {
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
                      ? "Digite o valor em ${widget.fiatCurrency}"
                      : "Digite o valor em ${widget.assetTicker}",
              hintStyle: TextStyle(
                fontFamily: "roboto",
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              prefixText: _isFiatMode ? '${widget.fiatCurrency} ' : "",
              prefixIcon: IconButton(
                icon: Text(
                  _isFiatMode ? widget.fiatCurrency : widget.assetTicker,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: "roboto",
                  ),
                ),
                onPressed: _toggleInputMode,
              ),
              suffixIcon:
                  widget.maxAmount != null
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
                          if (widget.maxAmount != null && widget.fees != null) {
                            final maxAmount =
                                widget.maxAmount! - widget.fees! - 1;
                            if (_isFiatMode) {
                              // Convert to BRL using fiat price
                              final amountInBRL =
                                  (maxAmount / pow(10, widget.assetPrecision)) *
                                      widget.fiatPrice -
                                  1;
                              _controller.text = amountInBRL.toStringAsFixed(2);
                            } else {
                              // Keep in crypto units
                              final amount =
                                  maxAmount / pow(10, widget.assetPrecision);
                              _controller.text = amount.toStringAsFixed(
                                widget.assetPrecision,
                              );
                            }
                            _notifyAmountChanged();
                            setState(() {});
                          }
                        },
                      )
                      : null,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "roboto",
            ),
            keyboardType: const TextInputType.numberWithOptions(
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
