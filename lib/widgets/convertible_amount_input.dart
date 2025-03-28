import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConvertibleAmountInput extends StatefulWidget {
  final String assetId;
  final String assetTicker;
  final String fiatCurrency;
  final int assetPrecision;
  final double fiatPrice;
  final TextEditingController? controller;
  final Function(double)? onAmountChanged;

  const ConvertibleAmountInput({
    Key? key,
    required this.assetId,
    required this.assetTicker,
    required this.fiatPrice,
    this.fiatCurrency = "BRL",
    this.assetPrecision = 8,
    this.controller,
    this.onAmountChanged,
  }) : super(key: key);

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
        final currentValue = double.tryParse(_controller.text) ?? 0.0;
        if (currentValue > 0 && widget.fiatPrice > 0) {
          if (_isFiatMode) {
            // Converting from crypto to fiat
            final fiatValue = currentValue * widget.fiatPrice;
            _controller.text = fiatValue.toStringAsFixed(2);
          } else {
            // Converting from fiat to crypto
            final cryptoValue = currentValue / widget.fiatPrice;
            _controller.text = cryptoValue.toStringAsFixed(
              widget.assetPrecision,
            );
          }
        }
      }

      // Notify parent about the change
      _notifyAmountChanged();
    });
  }

  void _notifyAmountChanged() {
    if (widget.onAmountChanged == null) return;

    final currentValue = double.tryParse(_controller.text) ?? 0.0;

    if (_isFiatMode) {
      final cryptoAmount = currentValue / widget.fiatPrice;
      widget.onAmountChanged!(cryptoAmount);
    } else {
      widget.onAmountChanged!(currentValue);
    }
  }

  String _getConversionText() {
    if (_controller.text.isEmpty) return "";

    final inputValue = double.tryParse(_controller.text) ?? 0.0;
    if (inputValue <= 0) return "";
    if (widget.fiatPrice == 0) return "Preço não disponível";

    if (_isFiatMode) {
      final cryptoAmount = inputValue / widget.fiatPrice;
      return "≈ ${cryptoAmount.toStringAsFixed(widget.assetPrecision)} ${widget.assetTicker}";
    }

    final fiatAmount = inputValue * widget.fiatPrice;
    return "≈ ${widget.fiatCurrency} ${fiatAmount.toStringAsFixed(2)}";
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
              prefixText: _isFiatMode ? widget.fiatCurrency + ' ' : "",
              suffixIcon: IconButton(
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
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
