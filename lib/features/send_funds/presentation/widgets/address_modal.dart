import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class AddressModal extends StatefulWidget {
  final String initialAddress;
  final Function(String) onAddressSet;

  const AddressModal({
    super.key,
    required this.initialAddress,
    required this.onAddressSet,
  });

  @override
  State<AddressModal> createState() => _AddressModalState();
}

class _AddressModalState extends State<AddressModal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAddressSet(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = _controller.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título e botão fechar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Endereço de envio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Campo de texto
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite ou cole o endereço',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'bc1q0gsgq2np...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.pinBackground,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botões
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(text: 'OK', onPressed: _handleConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
