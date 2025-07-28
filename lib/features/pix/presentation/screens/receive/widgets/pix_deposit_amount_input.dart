import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../providers.dart';

class PixDepositAmountInput extends ConsumerWidget {
  final TextEditingController controller = TextEditingController();

  PixDepositAmountInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositAmountInput = ref.read(depositAmountProvider.notifier);
    return TextField(
      controller: controller,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontSize: context.responsiveFont(36),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2
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
        CurrencyInputFormatter()
      ],
      onChanged: (val) => depositAmountInput.state = double.tryParse(controller.text) ?? 0.0
    );
  }
}