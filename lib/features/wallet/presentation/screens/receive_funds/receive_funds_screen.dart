import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/network_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/amount_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/generate_qr_button.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class ReceiveFundsScreen extends ConsumerWidget {
  const ReceiveFundsScreen({super.key});

  void _clearProviders(WidgetRef ref) {
    ref.invalidate(receiveAmountProvider);
    ref.invalidate(receiveAssetValueProvider);
    ref.invalidate(receiveSatsValueProvider);
    ref.invalidate(receiveFiatValueProvider);
    ref.invalidate(receiveDescriptionProvider);
    ref.invalidate(selectedReceiveAssetProvider);
    ref.invalidate(selectedReceiveNetworkProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _clearProviders(ref);
        }
      },
      child: PlatformSafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Receber Ativos"),
            leading: IconButton(
              onPressed: () {
                _clearProviders(ref);
                context.pop();
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              OfflineIndicator(
                onTap: () => OfflinePriceInfoOverlay.show(context),
              ),
              IconButton(
                onPressed: () => _showInfoOverlay(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AssetSelectorReceive(),

                  const SizedBox(height: 16),

                  const NetworkSelector(),

                  const SizedBox(height: 16),

                  const AmountFieldReceive(),

                  const SizedBox(height: 16),

                  const DescriptionFieldReceive(),

                  const SizedBox(height: 24),

                  const GenerateQRButton(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoOverlay(BuildContext context) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                right: 16,
                left: 16,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 8,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Como receber ativos',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => overlayEntry.remove(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoStep(
                          context,
                          '1',
                          'Selecione o ativo',
                          'Escolha qual criptomoeda você deseja receber',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoStep(
                          context,
                          '2',
                          'Escolha a rede',
                          'Bitcoin (on-chain), Lightning ou Liquid',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoStep(
                          context,
                          '3',
                          'Gere o QR code',
                          'Compartilhe com quem vai enviar o pagamento',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Toque fora desta área para fechar',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  Widget _buildInfoStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
