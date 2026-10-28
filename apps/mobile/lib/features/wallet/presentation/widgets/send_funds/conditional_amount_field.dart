import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import 'amount_field_send.dart';
import 'pre_defined_amount_widget.dart';

/// Shows the amount fixed by a payment request, or the amount field.
///
/// The two parts cross-fade when a pasted or scanned request changes the
/// mode.
class ConditionalAmountField extends ConsumerWidget {
  const ConditionalAmountField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPreDefinedAmount = ref.watch(hasPreDefinedAmountProvider);

    return SizeFadeSwitcher(
      child: hasPreDefinedAmount
          ? const PreDefinedAmountWidget(key: ValueKey('predefined'))
          : const AmountFieldSend(key: ValueKey('field')),
    );
  }
}
