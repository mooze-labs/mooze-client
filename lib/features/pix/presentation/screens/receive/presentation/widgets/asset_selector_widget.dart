import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import '../../../../providers.dart';
import '../../providers/lbtc_warning_provider.dart';

const _possibleAssets = [Asset.depix, Asset.lbtc];

class AssetSelectorWidget extends ConsumerWidget {
  const AssetSelectorWidget({super.key});

  Widget _buildAssetIcon(Asset asset) {
    return SvgPicture.asset(
      asset.iconPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }

  Future<bool?> _showLbtcFluctuationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Câmbio Flutuante',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Importante: o LBTC tem variação de preço.\nPor isso, o valor em reais que você recebe pode ser diferente do valor esperado.\nA conversão para reais usa a cotação do momento da finalização.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Entendi',
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Não exibir novamente'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    return FloatingLabelDropdown<Asset>(
      label: "Selecione um ativo",
      value: selectedAsset,
      items: _possibleAssets,
      onChanged: (asset) async {
        if (asset == Asset.lbtc) {
          final warningService = ref.read(lbtcWarningServiceProvider);
          final hasSeenWarning = await warningService.isWarningShown();
          if (!hasSeenWarning && context.mounted) {
            final dontShowAgain = await _showLbtcFluctuationDialog(
              context,
              ref,
            );
            if (dontShowAgain == true) {
              await warningService.setWarningShown();
            }
          }
        }

        ref.read(selectedAssetProvider.notifier).state = (asset ?? Asset.depix);
        ref.invalidate(assetQuoteProvider);
      },
      itemIconBuilder: (asset) => _buildAssetIcon(asset),
      itemLabelBuilder: (asset) => asset.name,
      borderColor: Theme.of(context).colorScheme.primary,
    );
  }
}
