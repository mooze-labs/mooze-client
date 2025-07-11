import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class MnemonicInputField extends ConsumerWidget {
  const MnemonicInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged:
          (value) => ref.read(mnemonicInputProvider.notifier).state = value,
      decoration: InputDecoration(
        labelText: 'Digite sua frase de recuperação',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
