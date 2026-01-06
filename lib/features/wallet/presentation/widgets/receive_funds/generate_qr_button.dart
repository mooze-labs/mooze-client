import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/qr_generation_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class GenerateQRButton extends ConsumerStatefulWidget {
  const GenerateQRButton({super.key});

  @override
  ConsumerState<GenerateQRButton> createState() => _GenerateQRButtonState();
}

class _GenerateQRButtonState extends ConsumerState<GenerateQRButton> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final validationState = ref.watch(receiveValidationControllerProvider);
    final qrAsyncState = ref.watch(qrGenerationControllerProvider);

    final isProviderLoading = qrAsyncState.when(
      loading: () => true,
      error: (_, __) => false,
      data: (qrState) => qrState.isLoading,
    );

    final isLoading = _isGenerating || isProviderLoading;
    final isEnabled = validationState.isValid && !isLoading;

    return PrimaryButton(
      onPressed: isEnabled ? () => _generateQR(context) : null,
      text: 'Gerar fatura',
      isEnabled: isEnabled,
      isLoading: isLoading,
    );
  }

  void _generateQR(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final selectedAsset = ref.read(selectedReceiveAssetProvider);
      final selectedNetwork = ref.read(selectedReceiveNetworkProvider);
      final amountText = ref.read(receiveAmountProvider);
      final description = ref.read(receiveDescriptionProvider);

      if (selectedAsset == null || selectedNetwork == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um ativo e rede')),
        );
        return;
      }

      double? finalAmount;
      if (amountText.isNotEmpty) {
        finalAmount = double.tryParse(amountText);
      }

      final String? finalDescription = description.isEmpty ? null : description;

      final qrController = ref.read(qrGenerationControllerProvider.notifier);

      await qrController.generateQRCode(
        network: selectedNetwork,
        asset: selectedAsset,
        amount: finalAmount,
        description: finalDescription,
      );

      if (!mounted) return;

      final qrAsyncState = ref.read(qrGenerationControllerProvider);

      qrAsyncState.when(
        loading: () {
          // Estado de loading tratado no build
        },
        error: (error, stack) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao gerar QR: $error')));
        },
        data: (qrState) {
          if (!mounted) return;
          if (qrState.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(qrState.error!)));
          } else if (qrState.displayAddress != null) {
            ref.read(receiveAmountProvider.notifier).state = '';
            ref.read(receiveAssetValueProvider.notifier).state = '';
            ref.read(receiveSatsValueProvider.notifier).state = '';
            ref.read(receiveFiatValueProvider.notifier).state = '';
            ref.read(receiveDescriptionProvider.notifier).state = '';
            context.push(
              '/receive-qr',
              extra: {
                'qrData': qrState.displayAddress,
                'displayAddress': qrState.displayAddress!,
                'asset': selectedAsset,
                'network': selectedNetwork,
                'amount': finalAmount,
                'description': finalDescription,
              },
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
