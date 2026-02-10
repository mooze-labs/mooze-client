import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final amountControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

final formattedAmountProvider = StateProvider<String>((ref) => '0');

final amountValidationProvider = Provider<bool>((ref) {
  final controller = ref.watch(amountControllerProvider);
  final text = controller.text;

  if (text.isEmpty) return false;

  final amount = double.tryParse(text);
  return amount != null && amount > 0;
});
