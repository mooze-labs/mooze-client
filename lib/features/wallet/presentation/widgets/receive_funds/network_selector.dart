import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';

class NetworkSelector extends ConsumerWidget {
  const NetworkSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNetwork = ref.watch(selectedReceiveNetworkProvider);
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );

    // Define redes disponíveis baseado no asset selecionado
    List<NetworkType> availableNetworks = _getAvailableNetworks(selectedAsset);

    // Se a network atual não está disponível para o asset, seleciona a primeira disponível
    if (selectedNetwork != null &&
        !availableNetworks.contains(selectedNetwork) &&
        availableNetworks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstAvailableNetwork = availableNetworks.first;
        ref.read(selectedReceiveNetworkProvider.notifier).state =
            firstAvailableNetwork;
        validationController.validateNetwork(firstAvailableNetwork);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione a rede',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Mostra informação sobre disponibilidade baseada no asset
        if (selectedAsset != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedAsset == Asset.btc
                        ? 'Bitcoin suporta todas as redes'
                        : '${selectedAsset.name} suporta apenas rede Liquid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Grid de opções de rede
        _buildNetworkGrid(
          context,
          ref,
          availableNetworks,
          selectedNetwork,
          validationController,
        ),

        if (selectedNetwork == NetworkType.lightning) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Para Lightning, o valor é obrigatório',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Define redes disponíveis baseado no asset
  List<NetworkType> _getAvailableNetworks(Asset? asset) {
    if (asset == null) return [];

    return switch (asset) {
      Asset.btc => [
        NetworkType.bitcoin,
        NetworkType.lightning,
        NetworkType.liquid,
      ],
      Asset.usdt => [NetworkType.liquid],
      Asset.depix => [NetworkType.liquid],
    };
  }

  // Constrói o grid de redes baseado nas disponíveis
  Widget _buildNetworkGrid(
    BuildContext context,
    WidgetRef ref,
    List<NetworkType> availableNetworks,
    NetworkType? selectedNetwork,
    dynamic validationController,
  ) {
    if (availableNetworks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Selecione um ativo primeiro',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    List<Widget> networkWidgets = [];

    for (int i = 0; i < availableNetworks.length; i++) {
      final network = availableNetworks[i];

      if (i > 0) {
        networkWidgets.add(const SizedBox(width: 8));
      }

      networkWidgets.add(
        Expanded(
          child: _NetworkOption(
            networkType: network,
            label: _getNetworkLabel(network),
            subtitle: _getNetworkSubtitle(network),
            icon: _getNetworkIcon(network),
            isSelected: selectedNetwork == network,
            onTap: () {
              ref.read(selectedReceiveNetworkProvider.notifier).state = network;
              validationController.validateNetwork(network);
            },
          ),
        ),
      );
    }

    return Row(children: networkWidgets);
  }

  String _getNetworkLabel(NetworkType network) {
    return switch (network) {
      NetworkType.bitcoin => 'Bitcoin',
      NetworkType.lightning => 'Lightning',
      NetworkType.liquid => 'Liquid',
      NetworkType.unknown => 'Desconhecida',
    };
  }

  String _getNetworkSubtitle(NetworkType network) {
    return switch (network) {
      NetworkType.bitcoin => 'On-chain',
      NetworkType.lightning => 'Instantâneo',
      NetworkType.liquid => 'Privado',
      NetworkType.unknown => '',
    };
  }

  IconData _getNetworkIcon(NetworkType network) {
    return switch (network) {
      NetworkType.bitcoin => Icons.link,
      NetworkType.lightning => Icons.flash_on,
      NetworkType.liquid => Icons.water_drop,
      NetworkType.unknown => Icons.help_outline,
    };
  }
}

class _NetworkOption extends StatelessWidget {
  final NetworkType networkType;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.networkType,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
