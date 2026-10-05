import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

class SwapButton extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final bool isBtcLbtcSwap;
  final bool isValidBtcLbtcAmount;
  final String? fromAmountText;
  final VoidCallback onPressed;

  const SwapButton({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.isBtcLbtcSwap,
    required this.isValidBtcLbtcAmount,
    required this.fromAmountText,
    required this.onPressed,
  });

  bool get _isButtonDisabled {
    if (isBtcLbtcSwap) {
      return isLoading || !isValidBtcLbtcAmount;
    }
    return isLoading || hasError || (fromAmountText?.isEmpty ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: _isButtonDisabled ? null : onPressed,
      text: isBtcLbtcSwap ? 'Converter' : 'Revisar Troca',
    );
  }
}
