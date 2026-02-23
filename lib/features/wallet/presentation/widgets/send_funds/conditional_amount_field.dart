import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import 'amount_field_send.dart';
import 'pre_defined_amount_widget.dart';

class ConditionalAmountField extends ConsumerWidget {
  const ConditionalAmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPreDefinedAmount = ref.watch(hasPreDefinedAmountProvider);

    if (hasPreDefinedAmount) {
      return const PreDefinedAmountWidget();
    } else {
      return const AmountFieldSend();
    }
  }
}
