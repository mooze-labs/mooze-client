import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class MnemonicInputField extends ConsumerStatefulWidget {
  const MnemonicInputField({super.key});

  @override
  ConsumerState<MnemonicInputField> createState() => _MnemonicInputFieldState();
}

class _MnemonicInputFieldState extends ConsumerState<MnemonicInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialValue = ref.read(mnemonicInputProvider);
    _controller = TextEditingController(text: initialValue);
    _controller.addListener(() {
      ref.read(mnemonicInputProvider.notifier).state = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Digite sua frase de recuperação',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      minLines: 3,
      maxLines: 5,
      textAlign: TextAlign.left,
      keyboardType: TextInputType.multiline,
      enableInteractiveSelection: true,
    );
  }
}
