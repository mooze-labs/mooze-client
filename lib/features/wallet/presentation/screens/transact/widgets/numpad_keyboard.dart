import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/transact_input_provider.dart';

import 'package:flutter/material.dart';

class NumpadKeyboard extends ConsumerWidget {
  const NumpadKeyboard({super.key});

  void _onNumberPressed(WidgetRef ref, String number) {
    final currentValue = ref.read(satoshiInputProvider);
    final newValue = int.tryParse('$currentValue$number') ?? 0;
    ref.read(satoshiInputProvider.notifier).state = newValue;
  }

  void _onDeletePressed(WidgetRef ref) {
    final currentValue = ref.read(satoshiInputProvider);
    if (currentValue > 0) {
      final stringValue = currentValue.toString();
      final newValue =
          stringValue.length > 1
              ? int.tryParse(
                    stringValue.substring(0, stringValue.length - 1),
                  ) ??
                  0
              : 0;
      ref.read(satoshiInputProvider.notifier).state = newValue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_PadItem> items = [
      _PadItem.text('1'),
      _PadItem.text('2'),
      _PadItem.text('3'),
      _PadItem.text('4'),
      _PadItem.text('5'),
      _PadItem.text('6'),
      _PadItem.text('7'),
      _PadItem.text('8'),
      _PadItem.text('9'),
      _PadItem.empty(),
      _PadItem.text('0'),
      _PadItem.backspace(),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        if (item.isEmpty) return const SizedBox.shrink();

        return InkWell(
          onTap: () {
            if (item.isBackspace) {
              _onDeletePressed(ref);
            } else {
              _onNumberPressed(ref, item.value);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                item.isBackspace
                    ? const Icon(Icons.backspace_outlined, size: 24)
                    : Text(
                      item.value,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                    ),
          ),
        );
      },
    );
  }
}

class _PadItem {
  final String value;
  final bool isBackspace;

  const _PadItem._(this.value, {this.isBackspace = false});

  factory _PadItem.text(String val) => _PadItem._(val);
  factory _PadItem.backspace() => _PadItem._('', isBackspace: true);
  factory _PadItem.empty() => _PadItem._('');

  bool get isEmpty => value.isEmpty && !isBackspace;
}
