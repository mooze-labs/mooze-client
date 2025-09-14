import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../screens/send_funds/qr_scanner_screen.dart';

class AddressField extends ConsumerWidget {
  const AddressField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressStateProvider);

    final displayText =
        addressState.isEmpty ? 'Digite o endereço aqui' : addressState;

    return GestureDetector(
      onTap: () => _openAddressInputModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5).copyWith(left: 12),
        decoration: BoxDecoration(
          color: AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => _openQRScanner(context),
              icon: Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQRScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );
  }

  void _openAddressInputModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressModal(),
    );
  }
}

class AddressModal extends ConsumerStatefulWidget {
  const AddressModal({super.key});

  @override
  ConsumerState<AddressModal> createState() => _AddressModalState();
}

class _AddressModalState extends ConsumerState<AddressModal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(addressControllerProvider);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite ou cole o endereço',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
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
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: "Cancelar",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: "OK",
                    onPressed: () {
                      final controller = ref.read(addressControllerProvider);
                      final address = controller.text.trim();
                      ref.read(addressStateProvider.notifier).state = address;

                      ref.invalidate(detectedAmountProvider);

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
