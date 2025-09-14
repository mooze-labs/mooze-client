import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

final syncedAddressControllerProvider =
    StateNotifierProvider<SyncedAddressController, String>((ref) {
      final controller = ref.watch(addressControllerProvider);
      return SyncedAddressController(controller);
    });

class SyncedAddressController extends StateNotifier<String> {
  final TextEditingController _controller;

  SyncedAddressController(this._controller) : super(_controller.text) {
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    state = _controller.text;
  }

  void updateText(String text) {
    _controller.text = text;
    state = text;
  }

  void clear() {
    _controller.clear();
    state = '';
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }
}

final addressValidationProvider = Provider<bool>((ref) {
  final controller = ref.watch(addressControllerProvider);
  final text = controller.text.trim();

  if (text.isEmpty) return false;

  return text.length > 10;
});

final clearAddressProvider = Provider<void Function()>((ref) {
  return () {
    final controller = ref.read(addressControllerProvider);
    controller.clear();
  };
});
