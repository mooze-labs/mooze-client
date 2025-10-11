import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import '../../providers.dart';

import 'account_limits_display_widget.dart';

class PixValueInputWidget extends ConsumerStatefulWidget {
  const PixValueInputWidget({super.key});

  @override
  ConsumerState<PixValueInputWidget> createState() =>
      _PixValueInputWidgetState();
}

class _PixValueInputWidgetState extends ConsumerState<PixValueInputWidget> {
  bool _showLimits = true;

  @override
  Widget build(BuildContext context) {
    final allowedDepositAmount = ref.watch(amountLimitProvider);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _buildContainerDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Valor do PIX',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsiveFont(20),
              fontWeight: FontWeight.w500,
            ),
          ),
          PixDepositAmountInput(),
          SizedBox(height: 10),
          _showLimits
              ? AccountLimitsDisplay(
                onToggleView: () {
                  setState(() {
                    _showLimits = false;
                  });
                },
              )
              : Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLimits = true;
                      });
                    },
                    child: InfoRow(
                      label: 'Meus níveis',
                      value: 'Ver Limite',
                      labelColor: Colors.white,
                      valueColor: AppColors.primaryColor,
                      fontSize: context.responsiveFont(14),
                    ),
                  ),
                  SizedBox(height: 12),
                  UserLevelDisplay(currentLevel: 3, currentProgress: 0.75),
                ],
              ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.pinBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
    );
  }
}

class PixDepositAmountInput extends ConsumerStatefulWidget {
  PixDepositAmountInput({super.key});

  @override
  ConsumerState<PixDepositAmountInput> createState() =>
      _PixDepositAmountInputState();
}

class _PixDepositAmountInputState extends ConsumerState<PixDepositAmountInput> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depositAmountInput = ref.read(depositAmountProvider.notifier);
    return TextField(
      controller: controller,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontSize: context.responsiveFont(36),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'R\$ 00,00',
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      onChanged: (val) {
        String cleanValue = val.replaceAll('R\$ ', '').replaceAll(',', '.');
        depositAmountInput.state = double.tryParse(cleanValue) ?? 0.0;
      },
    );
  }
}
