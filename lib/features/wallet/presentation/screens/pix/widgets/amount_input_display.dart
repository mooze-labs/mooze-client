import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class PixAmountInputDisplay extends ConsumerWidget {
  const PixAmountInputDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputString = ref.watch(amountInputStringProvider);

    double? value = double.tryParse(inputString);
    final amountText = '${(value ?? 0.0).toStringAsFixed(2)}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(amountText),
        ],
      ),
    );
  }
}
