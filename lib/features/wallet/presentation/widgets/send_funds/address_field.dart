import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';

class AddressField extends ConsumerStatefulWidget {
  const AddressField({super.key});

  @override
  ConsumerState<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends ConsumerState<AddressField> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentAddress = ref.read(addressStateProvider);
      final controller = ref.read(addressControllerProvider);
      if (currentAddress.isNotEmpty && controller.text != currentAddress) {
        controller.text = currentAddress;
      }
    });
  }

  void _autoSwitchAssetBasedOnNetwork(String address) {
    if (address.isEmpty) return;

    final networkType = NetworkDetectionService.detectNetworkType(address);
    final currentAsset = ref.read(selectedAssetProvider);

    if (currentAsset != Asset.btc && currentAsset != Asset.lbtc) {
      return;
    }

    Asset? newAsset;

    switch (networkType) {
      case NetworkType.bitcoin:
        if (currentAsset != Asset.btc) {
          newAsset = Asset.btc;
        }
        break;
      case NetworkType.lightning:
      case NetworkType.liquid:
        if (currentAsset != Asset.lbtc) {
          newAsset = Asset.lbtc;
        }
        break;

      case NetworkType.unknown:
        break;
    }

    if (newAsset != null) {
      ref.read(selectedAssetProvider.notifier).state = newAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(addressControllerProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    final addressError = validationState.errors.firstWhere(
      (error) =>
          error.contains('endereço') ||
          error.contains('Endereço') ||
          error.contains('destino'),
      orElse: () => '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Endereço de destino',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Digite ou cole o endereço',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: IconButton(
              onPressed: () => _openQRScanner(context),
              icon: Icon(
                Icons.qr_code_scanner,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Escanear QR Code',
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
            errorText: addressError.isEmpty ? null : addressError,
          ),
          maxLines: 3,
          minLines: 1,
          onChanged: (value) {
            final address = value.trim();
            ref.read(addressStateProvider.notifier).state = address;

            _autoSwitchAssetBasedOnNetwork(address);

            ref.invalidate(detectedAmountProvider);

            ref
                .read(sendValidationControllerProvider.notifier)
                .validateTransaction();
          },
        ),
      ],
    );
  }

  void _openQRScanner(BuildContext context) {
    context.push('/send-funds/scanner');
  }
}
